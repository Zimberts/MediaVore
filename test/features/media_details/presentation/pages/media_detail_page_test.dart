import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

class FakeMediaItem extends Fake implements MediaItem {}

void main() {
  late MockMediaRepository mockMediaRepository;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
    // Register mock repository
    locator.registerLazySingleton<MediaRepository>(() => mockMediaRepository);
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.isInWatchlist(any(), any())).thenAnswer((_) async => false);
  });

  tearDown(() {
    locator.reset();
  });

  const tItem = MediaItem(
    id: 1,
    title: 'Inception',
    posterPath: '/poster.jpg',
    releaseDate: '2010-07-16',
    overview: 'A mind-bending thriller',
    mediaType: MediaType.movie,
  );

  final tCast = [
    const CastMember(name: 'Leonardo DiCaprio', character: 'Cobb', profilePath: '/leo.jpg'),
  ];

  const tDirector = CrewMember(name: 'Christopher Nolan', job: 'Director');

  final tMediaDetails = MediaDetails(
    item: tItem,
    cast: tCast,
    director: tDirector,
  );

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: MediaDetailPage(item: tItem),
    );
  }

  group('MediaDetailPage', () {
    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      // arrange
      when(() => mockMediaRepository.getMediaDetails(tItem.id, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaDetails);

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget); // AppBar title
    });

    testWidgets('displays media details when loading is successful', (WidgetTester tester) async {
      // arrange
      when(() => mockMediaRepository.getMediaDetails(tItem.id, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaDetails);

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the future

      // assert
      expect(find.text('Inception'), findsNWidgets(2)); // Title in appbar and body
      expect(find.text('2010-07-16'), findsOneWidget);
      expect(find.text('Director: Christopher Nolan'), findsOneWidget);
      expect(find.text('A mind-bending thriller'), findsOneWidget);
      expect(find.text('Cast'), findsOneWidget);
      expect(find.text('Leonardo DiCaprio'), findsOneWidget);
    });

    testWidgets('displays error message when loading fails', (WidgetTester tester) async {
      // arrange
      when(() => mockMediaRepository.getMediaDetails(tItem.id, type: any(named: 'type')))
          .thenThrow(Exception('Network error'));

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the future

      // assert
      expect(find.text('Inception'), findsNWidgets(2)); // Title in appbar and body
      expect(find.text('A mind-bending thriller'), findsOneWidget);
      expect(find.text('Failed to load additional details.'), findsOneWidget);
    });
  });
}
