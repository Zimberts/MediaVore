import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    
    // Default mocks for SearchProvider init
    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockMediaRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockMediaRepository);
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
    
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockMediaRepository);
    
    // Default mocks for UI components
    when(() => mockMediaRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any())).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => []);
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
    const CastMember(id: 1, name: 'Leonardo DiCaprio', character: 'Cobb', profilePath: '/leo.jpg'),
  ];

  const tDirector = CrewMember(name: 'Christopher Nolan', job: 'Director');

  final tMediaDetails = MediaDetails(
    item: tItem,
    cast: tCast,
    director: tDirector,
  );

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: const MaterialApp(
        home: MediaDetailPage(item: tItem),
      ),
    );
  }

  group('MediaDetailPage', () {
    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      when(() => mockMediaRepository.getMediaDetails(tItem.id, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaDetails);

      await tester.pumpWidget(createWidgetUnderTest());

      // Should find at least one CPI (one in body, maybe one in SeenManager action)
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.text('Inception'), findsOneWidget); 
    });

    testWidgets('displays media details when loading is successful', (WidgetTester tester) async {
      when(() => mockMediaRepository.getMediaDetails(tItem.id, type: any(named: 'type')))
          .thenAnswer((_) async => tMediaDetails);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Run post-frame callbacks
      await tester.pumpAndSettle(); // Finish loading

      expect(find.text('Inception'), findsNWidgets(2)); 
      expect(find.text('2010-07-16'), findsOneWidget);
      expect(find.text('Director: Christopher Nolan'), findsOneWidget);
      expect(find.text('A mind-bending thriller'), findsOneWidget);
      expect(find.text('Cast'), findsOneWidget);
      expect(find.text('Leonardo DiCaprio'), findsOneWidget);
    });

    testWidgets('displays offline mode when loading fails with connection error', (WidgetTester tester) async {
      when(() => mockMediaRepository.getMediaDetails(tItem.id, type: any(named: 'type')))
          .thenThrow(Exception('SocketException: Connection failed'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Run post-frame callbacks
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Detailed information is unavailable without internet.'), findsOneWidget);
    });
  });
}
