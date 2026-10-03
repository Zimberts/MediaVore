import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late SettingsProvider settings;
  late LocaleService localeService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localeService = LocaleService.withDeviceLocales(
      prefs,
      () => const [Locale('en')],
    );
    settings = SettingsProvider(
      prefs,
      FakeTmdbCredentialStore(),
      localeService: localeService,
    );
  });

  Widget app() => ChangeNotifierProvider.value(
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
        locale: settings.locale,
        home: const SettingsPage(),
      ),
    ),
  );

  group('SettingsPage language', () {
    testWidgets('should switch the UI to French when picked', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français').last);
      await tester.pumpAndSettle();

      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Langue'), findsOneWidget);
      expect(localeService.tmdbLanguage, 'fr-FR');
    });
  });
}
