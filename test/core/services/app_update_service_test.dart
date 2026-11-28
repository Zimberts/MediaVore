import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/services/app_update_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDio mockDio;
  late Directory tempDir;
  late AppUpdateService service;

  setUpAll(() {
    registerFallbackValue(RequestOptions());
    registerFallbackValue(Options());
    registerFallbackValue(CancelToken());
  });

  setUp(() async {
    mockDio = _MockDio();
    tempDir = await Directory.systemTemp.createTemp('mediavore_update_test_');
    service = AppUpdateService.forTest(
      dio: mockDio,
      tempDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Map<String, dynamic> sampleReleaseJson({
    String tagName = 'v1.5.0',
    List<Map<String, dynamic>>? assets,
  }) => {
    'tag_name': tagName,
    'name': 'MediaVore $tagName',
    'body': '## Changes\n- Added auto update',
    'html_url': 'https://github.com/Zimberts/MediaVore/releases/tag/$tagName',
    'prerelease': false,
    'assets':
        assets ??
        [
          {
            'name': 'mediavore-$tagName.apk',
            'browser_download_url':
                'https://github.com/Zimberts/MediaVore/releases/download/$tagName/mediavore-$tagName.apk',
            'size': 1024,
          },
          {
            'name': 'mediavore-$tagName.apk.sha256',
            'browser_download_url':
                'https://github.com/Zimberts/MediaVore/releases/download/$tagName/mediavore-$tagName.apk.sha256',
            'size': 90,
          },
        ],
  };

  group('GitHubRelease', () {
    test(
      'should parse valid release JSON and locate APK and SHA-256 assets',
      () {
        final release = GitHubRelease.fromJson(sampleReleaseJson());
        expect(release.tagName, 'v1.5.0');
        expect(release.body, contains('Added auto update'));
        final apk = release.findApkAsset();
        expect(apk, isNotNull);
        expect(apk!.name, 'mediavore-v1.5.0.apk');
        final sha = release.findSha256Asset(apk.name);
        expect(sha, isNotNull);
        expect(sha!.name, 'mediavore-v1.5.0.apk.sha256');
      },
    );

    test(
      'should throw ParsingException when tag_name or html_url is missing',
      () {
        expect(
          () => GitHubRelease.fromJson({'html_url': 'https://example.com'}),
          throwsA(isA<ParsingException>()),
        );
        expect(
          () => GitHubRelease.fromJson({'tag_name': 'v1.5.0'}),
          throwsA(isA<ParsingException>()),
        );
      },
    );
  });

  group('SHA-256 verification', () {
    test('should parse sha256sum output and verify matching file', () async {
      final file = File('${tempDir.path}/test.apk')
        ..writeAsBytesSync([1, 2, 3, 4, 5]);
      final expectedHash = sha256.convert([1, 2, 3, 4, 5]).toString();

      await AppUpdateService.verifyFileSha256(
        file,
        '${expectedHash.toUpperCase()}  mediavore-v1.5.0.apk\n',
      );
    });

    test('should throw ChecksumMismatchException on hash mismatch', () async {
      final file = File('${tempDir.path}/test.apk')
        ..writeAsBytesSync([1, 2, 3, 4, 5]);
      final wrongHash = '0' * 64;

      await expectLater(
        AppUpdateService.verifyFileSha256(file, wrongHash),
        throwsA(isA<ChecksumMismatchException>()),
      );
    });

    test(
      'should throw ParsingException on invalid sha256 file format',
      () async {
        final file = File('${tempDir.path}/test.apk')
          ..writeAsBytesSync([1, 2, 3]);

        await expectLater(
          AppUpdateService.verifyFileSha256(file, 'not-a-hash'),
          throwsA(isA<ParsingException>()),
        );
      },
    );
  });

  group('checkForUpdate', () {
    test('should detect newer release', () async {
      when(
        () => mockDio.get<Object?>(
          latestReleaseUrl,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Object?>(
          requestOptions: RequestOptions(path: latestReleaseUrl),
          data: sampleReleaseJson(),
          statusCode: 200,
        ),
      );

      final result = await service.checkForUpdate();
      expect(result.hasUpdate, isTrue);
      expect(result.release.tagName, 'v1.5.0');
    });

    test('should report up to date when versions match', () async {
      when(
        () => mockDio.get<Object?>(
          latestReleaseUrl,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Object?>(
          requestOptions: RequestOptions(path: latestReleaseUrl),
          data: sampleReleaseJson(tagName: 'v1.4.4'),
          statusCode: 200,
        ),
      );

      final result = await service.checkForUpdate();
      expect(result.hasUpdate, isFalse);
    });

    test('should throw NetworkException on connection error', () async {
      when(
        () => mockDio.get<Object?>(
          latestReleaseUrl,
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: latestReleaseUrl),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        service.checkForUpdate(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw RateLimitException on 429 or exhausted 403', () async {
      final req = RequestOptions(path: latestReleaseUrl);
      when(
        () => mockDio.get<Object?>(
          latestReleaseUrl,
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: req,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: req,
            statusCode: 403,
            headers: Headers.fromMap({
              'x-ratelimit-remaining': ['0'],
            }),
          ),
        ),
      );

      await expectLater(
        service.checkForUpdate(),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('should throw ServerException on 500 response', () async {
      final req = RequestOptions(path: latestReleaseUrl);
      when(
        () => mockDio.get<Object?>(
          latestReleaseUrl,
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: req,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(requestOptions: req, statusCode: 500),
        ),
      );

      await expectLater(
        service.checkForUpdate(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('downloadAndVerifyApk', () {
    test('should download APK, report progress, and verify SHA-256', () async {
      final release = GitHubRelease.fromJson(sampleReleaseJson());
      final apkBytes = [10, 20, 30, 40];
      final expectedHash = sha256.convert(apkBytes).toString();
      final apkUrl = release.findApkAsset()!.downloadUrl;
      final shaUrl = release
          .findSha256Asset('mediavore-v1.5.0.apk')!
          .downloadUrl;

      when(
        () => mockDio.download(
          apkUrl,
          any<String>(),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((invocation) async {
        final savePath = invocation.positionalArguments[1] as String;
        final onProgress =
            invocation.namedArguments[#onReceiveProgress] as ProgressCallback?;
        File(savePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(apkBytes);
        onProgress?.call(2, 4);
        onProgress?.call(4, 4);
        return Response<Object?>(
          requestOptions: RequestOptions(path: apkUrl),
          statusCode: 200,
        );
      });

      when(
        () => mockDio.get<String>(
          shaUrl,
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<String>(
          requestOptions: RequestOptions(path: shaUrl),
          data: '$expectedHash  mediavore-v1.5.0.apk\n',
          statusCode: 200,
        ),
      );

      final progresses = <double>[];
      var verifyingCalled = false;
      final downloaded = await service.downloadAndVerifyApk(
        release,
        onProgress: progresses.add,
        onVerifying: () => verifyingCalled = true,
      );

      expect(downloaded.existsSync(), isTrue);
      expect(progresses, [0.5, 1.0]);
      expect(verifyingCalled, isTrue);
    });

    test('should delete APK and throw on SHA-256 mismatch', () async {
      final release = GitHubRelease.fromJson(sampleReleaseJson());
      final apkUrl = release.findApkAsset()!.downloadUrl;
      final shaUrl = release
          .findSha256Asset('mediavore-v1.5.0.apk')!
          .downloadUrl;
      late String savedPath;

      when(
        () => mockDio.download(
          apkUrl,
          any<String>(),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((invocation) async {
        savedPath = invocation.positionalArguments[1] as String;
        File(savedPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync([1, 2, 3]);
        return Response<Object?>(
          requestOptions: RequestOptions(path: apkUrl),
          statusCode: 200,
        );
      });

      when(
        () => mockDio.get<String>(
          shaUrl,
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<String>(
          requestOptions: RequestOptions(path: shaUrl),
          data: '${'f' * 64}  mediavore-v1.5.0.apk\n',
          statusCode: 200,
        ),
      );

      await expectLater(
        service.downloadAndVerifyApk(release),
        throwsA(isA<ChecksumMismatchException>()),
      );
      expect(File(savedPath).existsSync(), isFalse);
    });

    test(
      'should throw AppUpdateAssetNotFoundException when no APK asset exists',
      () async {
        final release = GitHubRelease.fromJson(
          sampleReleaseJson(assets: const []),
        );

        await expectLater(
          service.downloadAndVerifyApk(release),
          throwsA(isA<AppUpdateAssetNotFoundException>()),
        );
      },
    );
  });

  group('installApk', () {
    test('should invoke MethodChannel installApk and return result', () async {
      const channel = MethodChannel('test_app_update');
      String? invokedPath;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'installApk') {
              final args = call.arguments as Map<Object?, Object?>;
              invokedPath = args['filePath'] as String?;
              return true;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final channelService = AppUpdateService.forTest(
        dio: mockDio,
        methodChannel: channel,
      );
      final ok = await channelService.installApk('/tmp/mediavore.apk');
      expect(ok, isTrue);
      expect(invokedPath, '/tmp/mediavore.apk');
    });
  });
}
