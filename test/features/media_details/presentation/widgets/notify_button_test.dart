import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/notify_button.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(const MediaItem(id: 1, title: 'T', overview: '', releaseDate: ''));
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    
    // Default mocks for SearchProvider init
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.toggleNotification(any(), autoNotify: any(named: 'autoNotify')))
        .thenAnswer((_) async => Future.value());

    searchProvider = SearchProvider(mockRepository);
  });

  Widget createWidgetUnderTest(MediaItem item) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        home: Scaffold(
          body: NotifyButton(item: item),
        ),
      ),
    );
  }

  group('NotifyButton', () {
    testWidgets('does not show if movie is already released', (WidgetTester tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 10)).toString().split(' ')[0];
      final item = MediaItem(
        id: 1, 
        title: 'Old Movie', 
        mediaType: MediaType.movie, 
        overview: '', 
        releaseDate: pastDate,
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pump();

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('shows if movie is not yet released', (WidgetTester tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 10)).toString().split(' ')[0];
      final item = MediaItem(
        id: 1, 
        title: 'Future Movie', 
        mediaType: MediaType.movie, 
        overview: '', 
        releaseDate: futureDate,
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pump();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('shows if TV show is not ended', (WidgetTester tester) async {
      final item = const MediaItem(
        id: 2, 
        title: 'Ongoing Show', 
        mediaType: MediaType.tv, 
        overview: '', 
        releaseDate: '2023-01-01',
        status: 'Returning Series',
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pump();

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows active notification icon if item is in notifiedItems', (WidgetTester tester) async {
      final item = const MediaItem(
        id: 1, 
        title: 'Future Movie', 
        mediaType: MediaType.movie, 
        overview: '', 
        releaseDate: '2099-01-01',
      );

      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => [
        NotifiedItem(tmdbId: 1, type: MediaType.movie, title: 'Future Movie'),
      ]);
      await searchProvider.loadNotifiedItems();

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pump();

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('toggles notification when tapped', (WidgetTester tester) async {
      final item = const MediaItem(
        id: 1, 
        title: 'Future Movie', 
        mediaType: MediaType.movie, 
        overview: '', 
        releaseDate: '2099-01-01',
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      verify(() => mockRepository.toggleNotification(any())).called(1);
    });
  });
}
