import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late SettingsProvider settings;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    settings = SettingsProvider(mockPrefs, FakeTmdbCredentialStore('key'));
  });

  testWidgets(
    'SettingsPage displays advanced tracking switch and toggles setting',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('settings_advanced_tracking'));
      await tester.scrollUntilVisible(switchFinder, 200);
      expect(switchFinder, findsOneWidget);

      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, false);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settings.advancedTracking, true);
      verify(
        () => mockPrefs.setBool(SettingsProvider.advancedTrackingKey, true),
      ).called(1);
    },
  );

  testWidgets(
    'SettingsPage displays watch providers country dropdown and updates setting',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dropdownFinder = find.byKey(
        const Key('settings_watch_providers_country_dropdown'),
      );
      await tester.scrollUntilVisible(dropdownFinder, 200);
      expect(dropdownFinder, findsOneWidget);

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Select "United States"
      await tester.tap(find.text('United States').last);
      await tester.pumpAndSettle();

      expect(settings.watchProvidersCountry, 'US');
      verify(
        () => mockPrefs.setString(
          SettingsProvider.watchProvidersCountryKey,
          'US',
        ),
      ).called(1);
    },
  );

  testWidgets('SettingsPage includes JustWatch attribution in About dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: const MaterialApp(
          locale: Locale('fr'),
          supportedLocales: [Locale('fr'), Locale('en')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final aboutFinder = find.byType(AboutListTile);
    await tester.scrollUntilVisible(aboutFinder, 200);
    expect(aboutFinder, findsOneWidget);

    final aboutWidget = tester.widget<AboutListTile>(aboutFinder);
    expect(aboutWidget.aboutBoxChildren, isNotNull);
    final texts = aboutWidget.aboutBoxChildren!
        .whereType<Text>()
        .map((t) => t.data)
        .toList();
    expect(texts, contains('Données de streaming fournies par JustWatch.'));
  });

  testWidgets(
    'SettingsPage displays previous episodes setting and updates value',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dropdownFinder = find.byType(
        DropdownButton<PreviousEpisodesBehavior>,
      );
      await tester.scrollUntilVisible(dropdownFinder, 200);
      expect(dropdownFinder, findsOneWidget);

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Select "All seen"
      await tester.tap(find.text('All seen').last);
      await tester.pumpAndSettle();

      expect(settings.previousEpisodes, PreviousEpisodesBehavior.all);
      verify(
        () => mockPrefs.setString(SettingsProvider.previousEpisodesKey, 'all'),
      ).called(1);
    },
  );
}
