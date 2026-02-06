import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    // Default mocks for SharedPreferences (used by SettingsProvider)
    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    // Default mocks for SearchProvider init
    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockMediaRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getNotifiedItems()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockMediaRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    // Register the mock in GetIt locator because SavedMediaPage uses it directly
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerSingleton<MediaRepository>(mockMediaRepository);

    // Default mocks to prevent Null pointer errors during component initialization
    when(() => mockMediaRepository.isInWatchlist(any(), any())).thenAnswer((_) async => false);
    when(() => mockMediaRepository.getListPreviews(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const MainPage(),
      ),
    );
  }

  group('MainPage Navigation', () {
    testWidgets('starts on SavedMediaPage (My Lists)', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(SavedMediaPage), findsOneWidget);

      expect(find.byType(SearchPage, skipOffstage: false), findsOneWidget);
      expect(find.byType(SeenHistoryPage, skipOffstage: false), findsOneWidget);

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);
    });

    testWidgets('switches to Search tab', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final searchTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.search),
      );

      await tester.tap(searchTab);
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('switches to Seen tab', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final seenTab = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(Icons.history),
      );

      await tester.tap(seenTab);
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 2);
      expect(find.byType(SeenHistoryPage), findsOneWidget);
    });
  });
}
