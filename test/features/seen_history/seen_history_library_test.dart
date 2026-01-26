import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
  });

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
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
  });

  testWidgets('Switch to Library view groups episodes into a single title', (
    tester,
  ) async {
    final seen1 = SeenItem(
      id: 1,
      tmdbId: 11,
      title: 'Show X',
      type: MediaType.tv,
      seasonNumber: 1,
      episodeNumber: 1,
      seenDate: DateTime.now(),
    );
    final seen2 = SeenItem(
      id: 2,
      tmdbId: 11,
      title: 'Show X',
      type: MediaType.tv,
      seasonNumber: 1,
      episodeNumber: 2,
      seenDate: DateTime.now().subtract(const Duration(days: 1)),
    );

    when(
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => [seen1, seen2]);

    final mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    final settings = SettingsProvider(mockPrefs);
    final provider = SearchProvider(mockRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SearchProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const SeenHistoryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open filter options via the tuning icon in the search field suffix
    final tuneIcon = find.widgetWithIcon(IconButton, Icons.tune);
    expect(tuneIcon, findsOneWidget);
    await tester.tap(tuneIcon);
    await tester.pumpAndSettle();

    // In the bottom sheet, switch view mode to Library
    final dropdown = find.byType(DropdownButton<SeenViewMode>);
    expect(dropdown, findsWidgets);

    // Find the menu item text 'Library (Unique titles)' and tap it
    // First tap the trailing dropdown to open menu
    final viewModeDropdown = find.descendant(
      of: dropdown.first,
      matching: find.byType(DropdownButton<SeenViewMode>),
    );
    await tester.tap(dropdown.first);
    await tester.pumpAndSettle();

    // Select the Library option from popup
    await tester.tap(find.text('Library (Unique titles)').last);
    await tester.pumpAndSettle();

    // After selecting library, the page should display a single 'Show X' entry (grouped)
    expect(find.text('Show X'), findsOneWidget);
  });
}
