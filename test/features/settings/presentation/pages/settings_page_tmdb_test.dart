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

  /// Vertical position of the first ListTile, to compare section order.
  double firstTileTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(ListTile).first).dy;

  group('SettingsPage TMDB credential', () {
    testWidgets('should be the first item while unset', (tester) async {
      await tester.pumpWidget(app(await settingsWith('')));
      await tester.pumpAndSettle();

      final credentialTile = find.byKey(const Key('settings_tmdb_credential'));
      expect(credentialTile, findsOneWidget);
      expect(tester.getTopLeft(credentialTile).dy, firstTileTop(tester));
    });

    testWidgets('should not be first once set', (tester) async {
      await tester.pumpWidget(
        app(await settingsWith('0123456789abcdef0123456789abcdef')),
      );
      await tester.pumpAndSettle();

      final firstTile = tester.widget<ListTile>(find.byType(ListTile).first);
      expect(firstTile.key, isNot(const Key('settings_tmdb_credential')));
      expect(
        find.byKey(const Key('settings_language_dropdown')),
        findsOneWidget,
      );
    });
  });
}
