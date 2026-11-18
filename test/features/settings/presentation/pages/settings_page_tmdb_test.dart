import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

void main() {
  Future<SettingsProvider> settingsWith(String credential) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return SettingsProvider(prefs, FakeTmdbCredentialStore(credential));
  }

  Widget app(SettingsProvider settings) => ChangeNotifierProvider.value(
    value: settings,
    child: const MaterialApp(home: SettingsPage()),
  );

  group('SettingsPage TMDB credential', () {
    testWidgets(
      'is no longer present in SettingsPage as it moved to ProfilePage',
      (tester) async {
        await tester.pumpWidget(app(await settingsWith('')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('settings_tmdb_credential')), findsNothing);
        expect(
          find.byKey(const Key('settings_language_dropdown')),
          findsOneWidget,
        );
      },
    );
  });
}
