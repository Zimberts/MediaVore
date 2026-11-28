import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/utils/app_version.dart';
import 'package:mediavore/core/utils/json_maps.dart';
import 'package:mediavore/core/utils/semver.dart';
import 'package:path_provider/path_provider.dart';

/// GitHub API endpoint for the latest MediaVore release.
const String latestReleaseUrl =
    'https://api.github.com/repos/Zimberts/MediaVore/releases/latest';

/// Exception thrown when GitHub API rate limit is exceeded.
class RateLimitException extends ServerException {
  const RateLimitException(super.message, [super.statusCode, super.cause]);
}

/// Exception thrown when the downloaded APK fails SHA-256 verification.
class ChecksumMismatchException extends AppException {
  final String expected;
  final String actual;

  const ChecksumMismatchException({
    required this.expected,
    required this.actual,
  }) : super('SHA-256 mismatch: expected $expected, got $actual');
}

/// Exception thrown when no APK asset is attached to the release.
class AppUpdateAssetNotFoundException extends AppException {
  const AppUpdateAssetNotFoundException(super.message);
}

/// Exception thrown when the update download is cancelled by the user.
class AppUpdateCancelledException extends AppException {
  const AppUpdateCancelledException() : super('Update download cancelled');
}

/// Metadata for a single file attached to a GitHub release.
@immutable
class GitHubReleaseAsset {
  const GitHubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  final String name;
  final String downloadUrl;
  final int size;

  static GitHubReleaseAsset? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final downloadUrl = json['browser_download_url'];
    if (name is! String ||
        name.isEmpty ||
        downloadUrl is! String ||
        downloadUrl.isEmpty) {
      return null;
    }
    final rawSize = json['size'];
    final size = rawSize is int ? rawSize : 0;
    return GitHubReleaseAsset(name: name, downloadUrl: downloadUrl, size: size);
  }
}

/// Metadata for a GitHub release.
@immutable
class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.assets,
    this.prerelease = false,
  });

  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final List<GitHubReleaseAsset> assets;
  final bool prerelease;

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'];
    final htmlUrl = json['html_url'];
    if (tagName is! String || tagName.isEmpty) {
      throw const ParsingException('Missing tag_name in GitHub release JSON');
    }
    if (htmlUrl is! String || htmlUrl.isEmpty) {
      throw const ParsingException('Missing html_url in GitHub release JSON');
    }
    final rawName = json['name'];
    final rawBody = json['body'];
    final rawPrerelease = json['prerelease'];
    final assets = <GitHubReleaseAsset>[
      for (final assetJson in jsonObjectList(json['assets']))
        if (GitHubReleaseAsset.fromJson(assetJson) case final asset?) asset,
    ];
    return GitHubRelease(
      tagName: tagName,
      name: rawName is String && rawName.isNotEmpty ? rawName : tagName,
      body: rawBody is String ? rawBody : '',
      htmlUrl: htmlUrl,
      assets: assets,
      prerelease: rawPrerelease is bool ? rawPrerelease : false,
    );
  }

  /// Returns the primary APK asset (`mediavore-v*.apk`, or any `*.apk`).
  GitHubReleaseAsset? findApkAsset() {
    final preferred = RegExp(r'^mediavore-v.*\.apk$', caseSensitive: false);
    for (final asset in assets) {
      if (preferred.hasMatch(asset.name)) return asset;
    }
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) return asset;
    }
    return null;
  }

  /// Returns the `.sha256` asset matching [apkName], or any `*.apk.sha256`.
  GitHubReleaseAsset? findSha256Asset(String apkName) {
    final expectedName = '$apkName.sha256'.toLowerCase();
    for (final asset in assets) {
      if (asset.name.toLowerCase() == expectedName) return asset;
    }
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.apk.sha256')) return asset;
    }
    return null;
  }
}

/// Result of comparing the installed version against the latest GitHub release.
@immutable
class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.currentVersion,
    required this.remoteVersion,
    required this.release,
    required this.hasUpdate,
  });

  final SemVer currentVersion;
  final SemVer remoteVersion;
  final GitHubRelease release;
  final bool hasUpdate;
}

/// Checks, downloads, verifies, and launches installation of app updates from
/// GitHub Releases.
@lazySingleton
class AppUpdateService {
  AppUpdateService(Dio dio)
    : _dio = dio,
      _tempDirectoryProvider = getTemporaryDirectory,
      _methodChannel = const MethodChannel('fr.zimberts.mediavore/app_update');

  @visibleForTesting
  AppUpdateService.forTest({
    required Dio dio,
    Future<Directory> Function()? tempDirectoryProvider,
    MethodChannel? methodChannel,
  }) : _dio = dio,
       _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
       _methodChannel =
           methodChannel ??
           const MethodChannel('fr.zimberts.mediavore/app_update');

  final Dio _dio;
  final Future<Directory> Function() _tempDirectoryProvider;
  final MethodChannel _methodChannel;

  static final RegExp _sha256HexPattern = RegExp(r'\b([a-fA-F0-9]{64})\b');

  /// Extracts a 64-character lowercase SHA-256 hex digest from a `.sha256` file
  /// (e.g. `sha256sum` output `<hash>  mediavore-v1.5.0.apk`), or `null`.
  static String? parseSha256Digest(String content) {
    final match = _sha256HexPattern.firstMatch(content);
    return match?.group(1)?.toLowerCase();
  }

  /// Computes the lowercase hex SHA-256 digest of [file] by streaming chunks.
  static Future<String> computeFileSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }

  /// Verifies [file] against [expectedSha256Content]. Throws
  /// [ParsingException] if [expectedSha256Content] contains no valid digest,
  /// or [ChecksumMismatchException] if the computed hash differs.
  static Future<void> verifyFileSha256(
    File file,
    String expectedSha256Content,
  ) async {
    final expected = parseSha256Digest(expectedSha256Content);
    if (expected == null) {
      throw const ParsingException('Invalid SHA-256 checksum file format');
    }
    final actual = await computeFileSha256(file);
    if (actual != expected) {
      throw ChecksumMismatchException(expected: expected, actual: actual);
    }
  }

  /// Fetches the latest GitHub release metadata.
  Future<GitHubRelease> fetchLatestRelease() async {
    try {
      final response = await _dio.get<Object?>(
        latestReleaseUrl,
        options: Options(
          headers: const {'Accept': 'application/vnd.github+json'},
          responseType: ResponseType.json,
        ),
      );
      final map = jsonObject(response.data);
      if (map == null) {
        throw const ParsingException('Expected JSON object for GitHub release');
      }
      return GitHubRelease.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Checks whether a newer release than [currentVersion] is available.
  Future<AppUpdateCheckResult> checkForUpdate({
    String currentVersion = appVersion,
  }) async {
    final local = SemVer.tryParse(currentVersion);
    if (local == null) {
      throw ParsingException('Invalid local app version: "$currentVersion"');
    }
    final release = await fetchLatestRelease();
    final remote = SemVer.tryParse(release.tagName);
    if (remote == null) {
      throw ParsingException(
        'Invalid remote release tag: "${release.tagName}"',
      );
    }
    return AppUpdateCheckResult(
      currentVersion: local,
      remoteVersion: remote,
      release: release,
      hasUpdate: remote > local,
    );
  }

  /// Downloads the APK for [release] into a temporary directory, verifies its
  /// SHA-256 checksum if a `.sha256` asset is attached, and returns the local
  /// [File].
  Future<File> downloadAndVerifyApk(
    GitHubRelease release, {
    void Function(double progress)? onProgress,
    VoidCallback? onVerifying,
    CancelToken? cancelToken,
  }) async {
    final apkAsset = release.findApkAsset();
    if (apkAsset == null) {
      throw const AppUpdateAssetNotFoundException(
        'No APK asset found in GitHub release',
      );
    }

    final baseDir = await _tempDirectoryProvider();
    final updateDir = Directory('${baseDir.path}/mediavore_update');
    if (!updateDir.existsSync()) {
      await updateDir.create(recursive: true);
    }
    final targetPath = '${updateDir.path}/${apkAsset.name}';
    final targetFile = File(targetPath);
    if (targetFile.existsSync()) {
      await targetFile.delete();
    }

    try {
      await _dio.download(
        apkAsset.downloadUrl,
        targetPath,
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(minutes: 5)),
        onReceiveProgress: (received, total) {
          if (onProgress == null) return;
          final expectedTotal = total > 0 ? total : apkAsset.size;
          if (expectedTotal > 0) {
            onProgress((received / expectedTotal).clamp(0.0, 1.0));
          }
        },
      );
    } on DioException catch (e) {
      if (targetFile.existsSync()) {
        await targetFile.delete();
      }
      throw _mapDioException(e);
    }

    final shaAsset = release.findSha256Asset(apkAsset.name);
    if (shaAsset != null) {
      onVerifying?.call();
      try {
        final shaResponse = await _dio.get<String>(
          shaAsset.downloadUrl,
          cancelToken: cancelToken,
          options: Options(responseType: ResponseType.plain),
        );
        final shaText = shaResponse.data;
        if (shaText == null || shaText.isEmpty) {
          throw const ParsingException('Empty SHA-256 asset');
        }
        await verifyFileSha256(targetFile, shaText);
      } on DioException catch (e) {
        if (targetFile.existsSync()) {
          await targetFile.delete();
        }
        throw _mapDioException(e);
      } on AppException {
        if (targetFile.existsSync()) {
          await targetFile.delete();
        }
        rethrow;
      }
    }

    return targetFile;
  }

  /// Launches the Android system package installer on [filePath].
  /// Returns `true` if the installer activity was started, `false` otherwise.
  Future<bool> installApk(String filePath) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AppUpdateService] installApk failed: $e');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('[AppUpdateService] installApk unsupported: $e');
      return false;
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return const AppUpdateCancelledException();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Network error during update check', e);
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 429) {
      return RateLimitException(
        'GitHub API rate limit exceeded',
        statusCode,
        e,
      );
    }
    if (statusCode == 403) {
      final remaining = e.response?.headers.value('x-ratelimit-remaining');
      if (remaining == '0') {
        return RateLimitException(
          'GitHub API rate limit exceeded',
          statusCode,
          e,
        );
      }
    }
    if (statusCode != null) {
      return ServerException(
        'GitHub API returned HTTP $statusCode',
        statusCode,
        e,
      );
    }
    return NetworkException('Request failed during update check', e);
  }
}
