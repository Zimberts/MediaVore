import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/services/app_update_service.dart';
import 'package:mediavore/core/utils/semver.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/app_update_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/settings/presentation/widgets/app_update_dialog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

class _MockAppUpdateService extends Mock implements AppUpdateService {}

void main() {
  late SettingsProvider settings;
  late MockSharedPreferences mockPrefs;
  late _MockAppUpdateService mockUpdateService;
  late AppUpdateProvider updateProvider;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    settings = SettingsProvider(mockPrefs, FakeTmdbCredentialStore('key'));
    mockUpdateService = _MockAppUpdateService();
    updateProvider = AppUpdateProvider(mockUpdateService, isAndroid: true);
  });

  Widget buildApp() => MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<AppUpdateProvider>.value(value: updateProvider),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => AppMessageHost(child: child!),
      home: const SettingsPage(),
    ),
  );

  group('SettingsPage update controls', () {
    testWidgets('should toggle auto check updates setting', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(settings.autoCheckUpdates, isTrue);

      final switchTile = find.byKey(
        const Key('settings_auto_check_updates_switch'),
      );
      await tester.ensureVisible(switchTile);
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      expect(settings.autoCheckUpdates, isFalse);
      verify(
        () => mockPrefs.setBool(SettingsProvider.autoCheckUpdatesKey, false),
      ).called(1);
    });

    testWidgets('should open AppUpdateDialog when update is available', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const release = GitHubRelease(
        tagName: 'v1.5.0',
        name: 'v1.5.0',
        body: 'Release notes here',
        htmlUrl: 'https://github.com/Zimberts/MediaVore/releases/tag/v1.5.0',
        assets: [],
      );
      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => AppUpdateCheckResult(
          currentVersion: SemVer.parse('1.4.4'),
          remoteVersion: SemVer.parse('1.5.0'),
          release: release,
          hasUpdate: true,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('settings_check_updates_tile'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateDialog), findsOneWidget);
      expect(find.textContaining('Release notes here'), findsOneWidget);
    });

    testWidgets('should show up-to-date message when no update is available', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const release = GitHubRelease(
        tagName: 'v1.4.4',
        name: 'v1.4.4',
        body: '',
        htmlUrl: 'https://github.com/Zimberts/MediaVore/releases/tag/v1.4.4',
        assets: [],
      );
      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => AppUpdateCheckResult(
          currentVersion: SemVer.parse('1.4.4'),
          remoteVersion: SemVer.parse('1.4.4'),
          release: release,
          hasUpdate: false,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('settings_check_updates_tile'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateDialog), findsNothing);
      expect(find.textContaining('up to date'), findsOneWidget);

      // Advance past AppMessageHost auto-dismiss timer so no pending timers remain.
      await tester.pump(AppMessageHost.durationWithoutAction);
    });
  });
}
