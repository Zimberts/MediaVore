import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('SettingsPage displays advanced tracking switch and toggles setting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const Key('settings_advanced_tracking'));
    expect(switchFinder, findsOneWidget);

    final switchWidget = tester.widget<SwitchListTile>(switchFinder);
    expect(switchWidget.value, false);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(settings.advancedTracking, true);
    verify(() => mockPrefs.setBool(SettingsProvider.advancedTrackingKey, true)).called(1);
  });
}
