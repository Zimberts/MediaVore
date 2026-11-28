import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/settings/presentation/widgets/palette_picker_grid.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late SettingsProvider settings;

  Future<void> setUpSettings(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsProvider(prefs, FakeTmdbCredentialStore());
  }

  Widget app(Locale locale) => ChangeNotifierProvider.value(
    value: settings,
    child: Consumer<SettingsProvider>(
      builder: (context, settings, _) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          for (final language in supportedAppLanguages) language.locale,
        ],
        locale: locale,
        theme: settings.lightPalette.toThemeData(),
        darkTheme: settings.darkPalette.toThemeData(),
        themeMode: settings.themeMode,
        home: const SettingsPage(),
      ),
    ),
  );

  group('paletteName', () {
    test('should translate every core palette in every language', () {
      const expected = {
        'en': ['Paper', 'Sand', 'Mist', 'Ink', 'Night', 'OLED black'],
        'fr': ['Papier', 'Sable', 'Brume', 'Encre', 'Nuit', 'Noir OLED'],
      };
      expect(
        supportedAppLanguages.map((l) => l.locale.languageCode),
        unorderedEquals(expected.keys),
      );
      for (final language in supportedAppLanguages) {
        final l10n = lookupAppLocalizations(language.locale);
        expect(
          AppPalette.coreValues.map((p) => paletteName(l10n, p.id)),
          expected[language.locale.languageCode],
        );
      }
    });

    test('should translate all available palettes in all languages', () {
      for (final language in supportedAppLanguages) {
        final l10n = lookupAppLocalizations(language.locale);
        for (final palette in AppPalette.values) {
          final name = paletteName(l10n, palette.id);
          expect(
            name,
            isNotEmpty,
            reason: '${palette.id.name} in ${language.locale}',
          );
        }
      }
    });
  });

  group('SettingsPage palettes', () {
    testWidgets('should show the default palettes after a v1.3.0 install with '
        'custom palettes', (tester) async {
      await setUpSettings({'lightAppTheme': 4, 'darkAppTheme': 3});

      await tester.pumpWidget(app(const Locale('fr')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Papier'), findsOneWidget);
      expect(find.text('Encre'), findsOneWidget);
    });

    testWidgets('should list the light palettes and apply the picked '
        'one', (tester) async {
      await setUpSettings({});

      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();

      final lightGrid = find.byKey(const Key('settings_light_palette_grid'));
      expect(lightGrid, findsOneWidget);
      expect(find.text('Paper'), findsOneWidget);
      expect(find.text('Sand'), findsOneWidget);
      expect(find.text('Mist'), findsOneWidget);
      expect(
        find.descendant(of: lightGrid, matching: find.text('Night')),
        findsNothing,
      );

      final sandCard = find.byKey(const Key('settings_palette_sand'));
      await tester.ensureVisible(sandCard);
      await tester.tap(sandCard);
      await tester.pumpAndSettle();

      expect(settings.lightPalette, AppPalette.sand);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lightPalette'), 'sand');
      final context = tester.element(find.byType(SettingsPage));
      expect(Theme.of(context).scaffoldBackgroundColor, AppPalette.sand.bg);
      expect(tester.widget<PaletteSwatchCard>(sandCard).selected, isTrue);
    });

    testWidgets('should offer every light and dark palette, legacy ones '
        'included', (tester) async {
      await setUpSettings({});

      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();

      for (final (key, palettes) in [
        ('settings_light_palette_grid', AppPalette.lightPalettes),
        ('settings_dark_palette_grid', AppPalette.darkPalettes),
      ]) {
        final picker = find.byKey(Key(key));
        expect(
          find.descendant(of: picker, matching: find.byType(PaletteSwatchCard)),
          findsNWidgets(palettes.length),
        );
        for (final palette in palettes) {
          expect(
            find.descendant(
              of: picker,
              matching: find.byKey(Key('settings_palette_${palette.id.name}')),
            ),
            findsOneWidget,
            reason: palette.id.name,
          );
        }
      }
      expect(
        AppPalette.lightPalettes.length + AppPalette.darkPalettes.length,
        AppPalette.values.length,
      );
    });

    testWidgets('should apply and persist a legacy palette', (tester) async {
      await setUpSettings({'themeMode': ThemeMode.dark.index});

      await tester.pumpWidget(app(const Locale('fr')));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('settings_palette_espresso'));
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(settings.darkPalette, AppPalette.espresso);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('darkPalette'), 'espresso');
      final context = tester.element(find.byType(SettingsPage));
      expect(Theme.of(context).scaffoldBackgroundColor, AppPalette.espresso.bg);
      expect(tester.widget<PaletteSwatchCard>(card).selected, isTrue);
    });

    testWidgets('should mark a stored legacy palette as selected', (
      tester,
    ) async {
      await setUpSettings({'lightPalette': 'parchment'});

      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<PaletteSwatchCard>(
              find.byKey(const Key('settings_palette_parchment')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<PaletteSwatchCard>(
              find.byKey(const Key('settings_palette_paper')),
            )
            .selected,
        isFalse,
      );
    });

    testWidgets('should list the dark palettes and apply the picked '
        'one', (tester) async {
      await setUpSettings({'themeMode': ThemeMode.dark.index});

      await tester.pumpWidget(app(const Locale('fr')));
      await tester.pumpAndSettle();

      final darkGrid = find.byKey(const Key('settings_dark_palette_grid'));
      expect(darkGrid, findsOneWidget);
      expect(find.text('Encre'), findsOneWidget);
      expect(find.text('Nuit'), findsOneWidget);
      expect(find.text('Noir OLED'), findsOneWidget);

      final oledCard = find.byKey(const Key('settings_palette_oled'));
      await tester.ensureVisible(oledCard);
      await tester.tap(oledCard);
      await tester.pumpAndSettle();

      expect(settings.darkPalette, AppPalette.oled);
      final context = tester.element(find.byType(SettingsPage));
      expect(Theme.of(context).scaffoldBackgroundColor, AppPalette.oled.bg);
      expect(tester.widget<PaletteSwatchCard>(oledCard).selected, isTrue);
    });
  });
}
