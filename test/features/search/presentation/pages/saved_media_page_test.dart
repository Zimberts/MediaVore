import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';
import 'package:mediavore/core/di/injection.dart';

class FakeMediaItem extends Fake implements MediaItem {}

void main() {
  late MockMediaRepository mockMediaRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockMediaRepository);
    
    searchProvider = SearchProvider(mockMediaRepository);
    
    // Ensure default mocks for initialization
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockMediaRepository.getListPreviews(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: const MaterialApp(
        home: SavedMediaPage(),
      ),
    );
  }

  testWidgets('displays saved media items', (WidgetTester tester) async {
    final item = const MediaItem(
      id: 1,
      title: 'Inception',
      posterPath: null,
      releaseDate: '2010',
      overview: '...',
      mediaType: MediaType.movie,
    );
    
    when(() => mockMediaRepository.getListEntries('watchlist')).thenAnswer((_) async => ['1:movie']);
    when(() => mockMediaRepository.getMediaDetails(1, type: MediaType.movie)).thenAnswer((_) async => MediaDetails(
      item: item,
      cast: [],
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Trigger fetch
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
  });

  testWidgets('calls removeFromList when delete button is tapped', (WidgetTester tester) async {
     final item = const MediaItem(
      id: 1,
      title: 'Inception',
      posterPath: null,
      releaseDate: '2010',
      overview: '...',
      mediaType: MediaType.movie,
    );

    when(() => mockMediaRepository.getListEntries('watchlist')).thenAnswer((_) async => ['1:movie']);
    when(() => mockMediaRepository.getMediaDetails(1, type: MediaType.movie)).thenAnswer((_) async => MediaDetails(
      item: item,
      cast: [],
    ));
    when(() => mockMediaRepository.removeFromList(any(), any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await searchProvider.loadLists();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    verify(() => mockMediaRepository.removeFromList(1, MediaType.movie, 'watchlist')).called(1);
  });

  testWidgets('resetToDefault switches back to watchlist and reloads', (WidgetTester tester) async {
    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist', 'Favorites']);
    when(() => mockMediaRepository.getListEntries('Favorites')).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListEntries('watchlist')).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await searchProvider.loadLists();
    await tester.pumpAndSettle();

    // 1. Switch to 'Favorites'
    await tester.tap(find.text('Watchlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);

    // 2. Trigger reset
    final state = tester.state<SavedMediaPageState>(find.byType(SavedMediaPage));
    state.resetToDefault();
    await tester.pumpAndSettle();

    // 3. Verify
    expect(find.text('Watchlist'), findsOneWidget);
    verify(() => mockMediaRepository.getListEntries('watchlist')).called(greaterThan(0));
  });
}
