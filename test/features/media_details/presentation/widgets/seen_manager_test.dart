import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(SeenItem(tmdbId: 1, type: MediaType.movie, title: 'T', seenDate: DateTime.now()));
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

    searchProvider = SearchProvider(mockRepository);

    // Default mocks for UI components
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest({
    int tmdbId = 1,
    MediaType type = MediaType.movie,
    String title = 'Inception',
    bool compact = false,
  }) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: Scaffold(
          body: SeenManager(
            compact: compact,
            item: MediaItem(
              id: tmdbId,
              mediaType: type,
              title: title,
              overview: '',
              releaseDate: '',
            ),
          ),
        ),
      ),
    );
  }

  group('SeenManager', () {
    testWidgets('displays check_circle_outline icon when not seen', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Initial load

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays history icon when seen', (WidgetTester tester) async {
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2023)),
      ];
      // Mock both the direct repository call and the provider's seenItems list
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('tapping history icon opens bottom sheet', (WidgetTester tester) async {
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2023)),
      ];
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Viewing History'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when clearing history', (WidgetTester tester) async {
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2023)),
      ];
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      when(() => mockRepository.removeFromSeen(any(), any(),
          seasonNumber: any(named: 'seasonNumber'),
          episodeNumber: any(named: 'episodeNumber'))).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Long press on the ListTile (SeenManager uses ListTile when not compact)
      await tester.longPress(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Clear History'), findsOneWidget);

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.removeFromSeen(1, MediaType.movie)).called(1);
    });

    group('Tv Support', () {
      testWidgets('shows add multiple dialog for TV shows', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(type: MediaType.tv));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.check_circle_outline));
        await tester.pumpAndSettle();

        expect(find.text('Add Multiple Viewings'), findsOneWidget);
      });
    });
  });
}
