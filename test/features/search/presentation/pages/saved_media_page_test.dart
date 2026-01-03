import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';
import 'package:mediavore/core/di/injection.dart';

void main() {
  late MockMediaRepository mockMediaRepository;

  setUpAll(() {
    mockMediaRepository = MockMediaRepository();
    locator.registerLazySingleton<MediaRepository>(() => mockMediaRepository);
  });

  setUp(() {
    reset(mockMediaRepository);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: SavedMediaPage(),
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
      director: null,
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

    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => ['1:movie']);
    when(() => mockMediaRepository.getMediaDetails(1, type: MediaType.movie)).thenAnswer((_) async => MediaDetails(
      item: item,
      cast: [],
      director: null,
    ));
    when(() => mockMediaRepository.removeFromWatchlist(1, MediaType.movie)).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    verify(() => mockMediaRepository.removeFromWatchlist(1, MediaType.movie)).called(1);
  });
}
