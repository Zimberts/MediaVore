import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/core/di/injection.dart';

import '../../helpers/mocks.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
  });

  testWidgets(
    'SavedMedia display options -> switch to grid and change grid size',
    (tester) async {
      final mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getInt(any())).thenReturn(0);
      when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
      when(() => mockPrefs.getBool(any())).thenReturn(false);
      when(
        () => mockPrefs.setDouble(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      final settings = SettingsProvider(mockPrefs);
      final provider = SearchProvider(mockRepository);

      // register repository used by SavedMediaPage
      locator.registerSingleton<MediaRepository>(mockRepository);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
          ],
          child: MaterialApp(
            theme: DefaultLightPalette().toThemeData(),
            home: const SavedMediaPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the display mode icon
      final displayIcon = find.byIcon(Icons.grid_on);
      expect(displayIcon, findsOneWidget);
      await tester.tap(displayIcon);
      await tester.pumpAndSettle();

      // The bottom sheet should show Display Options
      expect(find.text('Display Options'), findsOneWidget);

      // Toggle to grid by tapping the second ToggleButton (index 1)
      final toggleButtons = find.byType(ToggleButtons);
      expect(toggleButtons, findsOneWidget);
      // Tap the grid toggle (second child)
      await tester.tap(
        find.descendant(
          of: toggleButtons,
          matching: find.byIcon(Icons.grid_view),
        ),
      );
      await tester.pumpAndSettle();

      // SettingsProvider should now show grid display mode
      expect(settings.displayMode, equals(DisplayMode.grid));

      // Slide the grid size slider to a larger value
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(settings.gridSize >= 2.0 && settings.gridSize <= 5.0, isTrue);

      await locator.reset();
    },
  );
}
