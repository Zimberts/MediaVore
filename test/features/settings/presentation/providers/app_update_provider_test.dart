import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/services/app_update_service.dart';
import 'package:mediavore/core/utils/semver.dart';
import 'package:mediavore/features/settings/presentation/providers/app_update_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppUpdateService extends Mock implements AppUpdateService {}

void main() {
  late _MockAppUpdateService mockService;
  late AppUpdateProvider provider;

  const sampleRelease = GitHubRelease(
    tagName: 'v1.5.0',
    name: 'v1.5.0',
    body: 'Changelog',
    htmlUrl: 'https://github.com/Zimberts/MediaVore/releases/tag/v1.5.0',
    assets: [],
  );

  setUpAll(() {
    registerFallbackValue(sampleRelease);
    registerFallbackValue(CancelToken());
  });

  setUp(() {
    mockService = _MockAppUpdateService();
    provider = AppUpdateProvider(mockService, isAndroid: true);
  });

  group('AppUpdateProvider', () {
    test('should transition to available when newer release exists', () async {
      when(() => mockService.checkForUpdate()).thenAnswer(
        (_) async => AppUpdateCheckResult(
          currentVersion: SemVer.parse('1.4.4'),
          remoteVersion: SemVer.parse('1.5.0'),
          release: sampleRelease,
          hasUpdate: true,
        ),
      );

      final found = await provider.checkForUpdate();
      expect(found, isTrue);
      expect(provider.status, AppUpdateStatus.available);
      expect(provider.availableRelease, sampleRelease);
    });

    test(
      'should transition to upToDate when no newer release exists',
      () async {
        when(() => mockService.checkForUpdate()).thenAnswer(
          (_) async => AppUpdateCheckResult(
            currentVersion: SemVer.parse('1.4.4'),
            remoteVersion: SemVer.parse('1.4.4'),
            release: sampleRelease,
            hasUpdate: false,
          ),
        );

        final found = await provider.checkForUpdate();
        expect(found, isFalse);
        expect(provider.status, AppUpdateStatus.upToDate);
        expect(provider.availableRelease, isNull);
      },
    );

    test('should swallow errors in silent mode and keep idle status', () async {
      when(
        () => mockService.checkForUpdate(),
      ).thenThrow(const NetworkException('offline'));

      final found = await provider.checkForUpdate(silent: true);
      expect(found, isFalse);
      expect(provider.hasCheckedOnStartup, isTrue);
      expect(provider.status, AppUpdateStatus.idle);
      expect(provider.errorKind, isNull);
    });

    test(
      'should map rate limit and network errors in non-silent mode',
      () async {
        when(
          () => mockService.checkForUpdate(),
        ).thenThrow(const RateLimitException('rate limit', 403));

        await provider.checkForUpdate();
        expect(provider.status, AppUpdateStatus.error);
        expect(provider.errorKind, AppUpdateErrorKind.rateLimit);
      },
    );

    test('should download, verify, and trigger Android installer', () async {
      when(() => mockService.checkForUpdate()).thenAnswer(
        (_) async => AppUpdateCheckResult(
          currentVersion: SemVer.parse('1.4.4'),
          remoteVersion: SemVer.parse('1.5.0'),
          release: sampleRelease,
          hasUpdate: true,
        ),
      );
      when(
        () => mockService.downloadAndVerifyApk(
          sampleRelease,
          cancelToken: any(named: 'cancelToken'),
          onProgress: any(named: 'onProgress'),
          onVerifying: any(named: 'onVerifying'),
        ),
      ).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[#onProgress] as void Function(double)?;
        final onVerifying =
            invocation.namedArguments[#onVerifying] as VoidCallback?;
        onProgress?.call(0.5);
        onVerifying?.call();
        return File('/tmp/mediavore-v1.5.0.apk');
      });
      when(
        () => mockService.installApk('/tmp/mediavore-v1.5.0.apk'),
      ).thenAnswer((_) async => true);

      await provider.checkForUpdate();
      await provider.downloadAndInstall();

      expect(provider.downloadedApkPath, '/tmp/mediavore-v1.5.0.apk');
      expect(provider.status, AppUpdateStatus.readyToInstall);
      verify(
        () => mockService.installApk('/tmp/mediavore-v1.5.0.apk'),
      ).called(1);
    });

    test(
      'should set installFailed error when installApk returns false',
      () async {
        when(() => mockService.checkForUpdate()).thenAnswer(
          (_) async => AppUpdateCheckResult(
            currentVersion: SemVer.parse('1.4.4'),
            remoteVersion: SemVer.parse('1.5.0'),
            release: sampleRelease,
            hasUpdate: true,
          ),
        );
        when(
          () => mockService.downloadAndVerifyApk(
            sampleRelease,
            cancelToken: any(named: 'cancelToken'),
            onProgress: any(named: 'onProgress'),
            onVerifying: any(named: 'onVerifying'),
          ),
        ).thenAnswer((_) async => File('/tmp/mediavore-v1.5.0.apk'));
        when(
          () => mockService.installApk('/tmp/mediavore-v1.5.0.apk'),
        ).thenAnswer((_) async => false);

        await provider.checkForUpdate();
        await provider.downloadAndInstall();

        expect(provider.status, AppUpdateStatus.error);
        expect(provider.errorKind, AppUpdateErrorKind.installFailed);
      },
    );
  });
}
