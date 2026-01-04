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

void main() {
  late MockMediaRepository mockMediaRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    mockMediaRepository = MockMediaRepository();
    locator.registerLazySingleton<MediaRepository>(() => mockMediaRepository);
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    reset(mockMediaRepository);
    searchProvider = SearchProvider(mockMediaRepository);
    
    // Ensure getWatchlistEntries returns something for the provider to initialize
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
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
    final items = [
      const MediaItem(
        id: 1,
        title: 'Inception',
        posterPath: null,
        releaseDate: '2010',
        overview: '...',
        mediaType: MediaType.movie,
      ),
    ];
    
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => ['1:movie']);
    when(() => mockMediaRepository.getMediaDetails(1, type: MediaType.movie)).thenAnswer((_) async => MediaDetails(
      item: items[0],
      cast: [],
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
  });

  testWidgets('calls removeFromWatchlist when delete button is tapped', (WidgetTester tester) async {
     final item = const MediaItem(
      id: 1,
      title: 'Inception',
      posterPath: null,
      releaseDate: '2010',
      overview: '...',
      mediaType: MediaType.movie,
    );

    // Initial load for provider and page
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => ['1:movie']);
    when(() => mockMediaRepository.getMediaDetails(1, type: MediaType.movie)).thenAnswer((_) async => MediaDetails(
      item: item,
      cast: [],
    ));
    when(() => mockMediaRepository.removeFromWatchlist(1, MediaType.movie)).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    // Load watchlist into provider
    await searchProvider.loadWatchlist();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    verify(() => mockMediaRepository.removeFromWatchlist(1, MediaType.movie)).called(1);
  });
}
