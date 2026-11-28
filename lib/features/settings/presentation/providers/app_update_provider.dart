import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/services/app_update_service.dart';
import 'package:mediavore/core/utils/app_version.dart';

enum AppUpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  verifying,
  readyToInstall,
  installing,
  error,
}

enum AppUpdateErrorKind {
  network,
  rateLimit,
  server,
  parsing,
  checksumMismatch,
  noApkAsset,
  installFailed,
  unknown,
}

/// Manages checking, downloading, verifying, and installing app updates.
class AppUpdateProvider with ChangeNotifier {
  AppUpdateProvider(
    this._service, {
    bool? isAndroid,
    String currentVersion = appVersion,
  }) : _isAndroidOverride = isAndroid,
       _currentVersion = currentVersion;

  final AppUpdateService _service;
  final bool? _isAndroidOverride;
  final String _currentVersion;

  AppUpdateStatus _status = AppUpdateStatus.idle;
  GitHubRelease? _availableRelease;
  double _downloadProgress = 0.0;
  String? _downloadedApkPath;
  AppUpdateErrorKind? _errorKind;
  CancelToken? _cancelToken;
  bool _hasCheckedOnStartup = false;

  AppUpdateStatus get status => _status;
  GitHubRelease? get availableRelease => _availableRelease;
  double get downloadProgress => _downloadProgress;
  String? get downloadedApkPath => _downloadedApkPath;
  AppUpdateErrorKind? get errorKind => _errorKind;
  String get currentVersion => _currentVersion;
  bool get hasCheckedOnStartup => _hasCheckedOnStartup;

  /// Whether direct APK download & installation is supported on this platform.
  bool get isAndroid =>
      _isAndroidOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  bool get isBusy =>
      _status == AppUpdateStatus.checking ||
      _status == AppUpdateStatus.downloading ||
      _status == AppUpdateStatus.verifying ||
      _status == AppUpdateStatus.installing;

  /// Checks GitHub Releases for a newer version.
  ///
  /// When [silent] is `true` (e.g. startup check), errors are swallowed and
  /// leave the provider in [AppUpdateStatus.idle].
  /// Returns `true` if a newer version is available.
  Future<bool> checkForUpdate({bool silent = false}) async {
    if (isBusy) return false;
    if (silent) _hasCheckedOnStartup = true;

    _status = AppUpdateStatus.checking;
    _errorKind = null;
    notifyListeners();

    try {
      final result = await _service.checkForUpdate(
        currentVersion: _currentVersion,
      );
      if (result.hasUpdate) {
        _availableRelease = result.release;
        _status = AppUpdateStatus.available;
        notifyListeners();
        return true;
      }
      _availableRelease = null;
      _status = silent ? AppUpdateStatus.idle : AppUpdateStatus.upToDate;
      notifyListeners();
      return false;
    } on AppException catch (e) {
      if (silent) {
        _status = AppUpdateStatus.idle;
        _errorKind = null;
      } else {
        _status = AppUpdateStatus.error;
        _errorKind = _mapError(e);
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AppUpdateProvider] Unexpected error checking update: $e');
      if (silent) {
        _status = AppUpdateStatus.idle;
        _errorKind = null;
      } else {
        _status = AppUpdateStatus.error;
        _errorKind = AppUpdateErrorKind.unknown;
      }
      notifyListeners();
      return false;
    }
  }

  /// Downloads and verifies the APK for [availableRelease], then triggers the
  /// Android package installer if verification succeeds.
  Future<void> downloadAndInstall() async {
    final release = _availableRelease;
    if (release == null || isBusy) return;

    _cancelToken = CancelToken();
    _status = AppUpdateStatus.downloading;
    _downloadProgress = 0.0;
    _errorKind = null;
    notifyListeners();

    try {
      final file = await _service.downloadAndVerifyApk(
        release,
        cancelToken: _cancelToken,
        onProgress: (progress) {
          if (_status != AppUpdateStatus.downloading) return;
          _downloadProgress = progress;
          notifyListeners();
        },
        onVerifying: () {
          _status = AppUpdateStatus.verifying;
          notifyListeners();
        },
      );
      _downloadedApkPath = file.path;
      _status = AppUpdateStatus.readyToInstall;
      notifyListeners();
      await installDownloadedApk();
    } on AppUpdateCancelledException {
      _status = AppUpdateStatus.available;
      _downloadProgress = 0.0;
      _errorKind = null;
      notifyListeners();
    } on AppException catch (e) {
      _status = AppUpdateStatus.error;
      _errorKind = _mapError(e);
      notifyListeners();
    } catch (e) {
      debugPrint('[AppUpdateProvider] Unexpected download error: $e');
      _status = AppUpdateStatus.error;
      _errorKind = AppUpdateErrorKind.unknown;
      notifyListeners();
    } finally {
      _cancelToken = null;
    }
  }

  /// Launches the Android installer for the already-downloaded APK.
  Future<bool> installDownloadedApk() async {
    final path = _downloadedApkPath;
    if (path == null || _status == AppUpdateStatus.installing) return false;

    _status = AppUpdateStatus.installing;
    _errorKind = null;
    notifyListeners();

    final launched = await _service.installApk(path);
    if (launched) {
      _status = AppUpdateStatus.readyToInstall;
      notifyListeners();
      return true;
    }

    _status = AppUpdateStatus.error;
    _errorKind = AppUpdateErrorKind.installFailed;
    notifyListeners();
    return false;
  }

  /// Cancels an in-progress APK download.
  void cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
  }

  /// Clears transient error/up-to-date states back to [AppUpdateStatus.idle]
  /// (or [AppUpdateStatus.available] if a release was found).
  void dismissError() {
    if (_availableRelease != null) {
      _status = AppUpdateStatus.available;
    } else {
      _status = AppUpdateStatus.idle;
    }
    _errorKind = null;
    notifyListeners();
  }

  AppUpdateErrorKind _mapError(AppException e) {
    if (e is RateLimitException) return AppUpdateErrorKind.rateLimit;
    if (e is NetworkException) return AppUpdateErrorKind.network;
    if (e is ServerException) return AppUpdateErrorKind.server;
    if (e is ParsingException) return AppUpdateErrorKind.parsing;
    if (e is ChecksumMismatchException) {
      return AppUpdateErrorKind.checksumMismatch;
    }
    if (e is AppUpdateAssetNotFoundException) {
      return AppUpdateErrorKind.noApkAsset;
    }
    return AppUpdateErrorKind.unknown;
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Provider disposed');
    super.dispose();
  }
}
