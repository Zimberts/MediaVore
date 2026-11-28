import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/services/app_update_service.dart';
import 'package:mediavore/core/utils/semver.dart';
import 'package:mediavore/features/settings/presentation/providers/app_update_provider.dart';
import 'package:mediavore/features/settings/presentation/widgets/app_update_dialog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAppUpdateService extends Mock implements AppUpdateService {}

void main() {
  late _MockAppUpdateService mockService;

  const sampleRelease = GitHubRelease(
    tagName: 'v1.5.0',
    name: 'MediaVore v1.5.0',
    body: '- Added in-app updates',
    htmlUrl: 'https://github.com/Zimberts/MediaVore/releases/tag/v1.5.0',
    assets: [],
  );

  setUpAll(() {
    registerFallbackValue(sampleRelease);
    registerFallbackValue(CancelToken());
  });

  setUp(() {
    mockService = _MockAppUpdateService();
    when(
      () => mockService.checkForUpdate(
        currentVersion: any(named: 'currentVersion'),
      ),
    ).thenAnswer(
      (_) async => AppUpdateCheckResult(
        currentVersion: SemVer.parse('1.4.4'),
        remoteVersion: SemVer.parse('1.5.0'),
        release: sampleRelease,
        hasUpdate: true,
      ),
    );
  });

  Widget buildSubject(
    AppUpdateProvider provider, {
    UpdateUrlLauncher? urlLauncher,
  }) => ChangeNotifierProvider<AppUpdateProvider>.value(
    value: provider,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AppUpdateDialog(release: sampleRelease, urlLauncher: urlLauncher),
      ),
    ),
  );

  group('AppUpdateDialog', () {
    testWidgets('should show download button and progress on Android', (
      tester,
    ) async {
      final downloadCompleter = Completer<File>();
      when(
        () => mockService.downloadAndVerifyApk(
          sampleRelease,
          cancelToken: any(named: 'cancelToken'),
          onProgress: any(named: 'onProgress'),
          onVerifying: any(named: 'onVerifying'),
        ),
      ).thenAnswer((invocation) {
        final onProgress =
            invocation.namedArguments[#onProgress] as void Function(double)?;
        onProgress?.call(0.4);
        return downloadCompleter.future;
      });
      when(() => mockService.installApk(any())).thenAnswer((_) async => true);

      final provider = AppUpdateProvider(mockService, isAndroid: true);
      await provider.checkForUpdate();

      await tester.pumpWidget(buildSubject(provider));
      await tester.pumpAndSettle();

      expect(find.textContaining('v1.5.0'), findsOneWidget);
      expect(find.textContaining('Added in-app updates'), findsOneWidget);
      expect(find.byKey(AppUpdateDialog.downloadButtonKey), findsOneWidget);

      await tester.tap(find.byKey(AppUpdateDialog.downloadButtonKey));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('40%'), findsOneWidget);

      downloadCompleter.complete(File('/tmp/mediavore-v1.5.0.apk'));
      await tester.pumpAndSettle();

      expect(find.byKey(AppUpdateDialog.installButtonKey), findsOneWidget);
    });

    testWidgets(
      'should show browser fallback when checksum verification fails',
      (tester) async {
        Uri? openedUrl;
        when(
          () => mockService.downloadAndVerifyApk(
            sampleRelease,
            cancelToken: any(named: 'cancelToken'),
            onProgress: any(named: 'onProgress'),
            onVerifying: any(named: 'onVerifying'),
          ),
        ).thenThrow(
          const ChecksumMismatchException(expected: 'aaa', actual: 'bbb'),
        );

        final provider = AppUpdateProvider(mockService, isAndroid: true);
        await provider.checkForUpdate();

        await tester.pumpWidget(
          buildSubject(
            provider,
            urlLauncher: (uri) async {
              openedUrl = uri;
              return true;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(AppUpdateDialog.downloadButtonKey));
        await tester.pumpAndSettle();

        expect(find.textContaining('SHA-256'), findsOneWidget);
        expect(
          find.byKey(AppUpdateDialog.openBrowserButtonKey),
          findsOneWidget,
        );

        await tester.tap(find.byKey(AppUpdateDialog.openBrowserButtonKey));
        await tester.pumpAndSettle();

        expect(openedUrl?.toString(), sampleRelease.htmlUrl);
      },
    );

    testWidgets('should show only browser launch on iOS', (tester) async {
      Uri? openedUrl;
      final provider = AppUpdateProvider(mockService, isAndroid: false);
      await provider.checkForUpdate();

      await tester.pumpWidget(
        buildSubject(
          provider,
          urlLauncher: (uri) async {
            openedUrl = uri;
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppUpdateDialog.downloadButtonKey), findsNothing);
      expect(find.byKey(AppUpdateDialog.openBrowserButtonKey), findsOneWidget);

      await tester.tap(find.byKey(AppUpdateDialog.openBrowserButtonKey));
      await tester.pumpAndSettle();

      expect(openedUrl?.toString(), sampleRelease.htmlUrl);
    });
  });
}
