import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
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
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    
    // Default mocks for SearchProvider init
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockRepository);
    
    // Default mocks for UI components
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest({
    int tmdbId = 1,
    MediaType type = MediaType.movie,
    String title = 'Inception',
  }) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        home: Scaffold(
          body: SeenManager(
            tmdbId: tmdbId,
            type: type,
            title: title,
          ),
        ),
      ),
    );
  }

  group('SeenManager', () {
    testWidgets('displays visibility_off icon when not seen', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Initial load

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('displays visibility icon and count badge when seen multiple times', (WidgetTester tester) async {
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2023)),
        SeenItem(id: 2, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2022)),
      ];
      when(() => mockRepository.getSeenStatus(1, MediaType.movie)).thenAnswer((_) async => viewings);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Badge count
    });

    testWidgets('tapping icon opens bottom sheet when already seen', (WidgetTester tester) async {
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2023)),
      ];
      when(() => mockRepository.getSeenStatus(1, MediaType.movie)).thenAnswer((_) async => viewings);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Add another viewing'), findsOneWidget);
      expect(find.text('Remove all viewings'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when deleting a viewing', (WidgetTester tester) async {
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2023)),
      ];
      when(() => mockRepository.getSeenStatus(1, MediaType.movie)).thenAnswer((_) async => viewings);
      when(() => mockRepository.deleteSeenEntry(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Tap delete on the viewing entry in the sheet
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm dialog should be visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Remove log?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.deleteSeenEntry(1)).called(1);
    });

    testWidgets('shows confirmation dialog when removing all viewings', (WidgetTester tester) async {
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Inception', seenDate: DateTime(2023)),
      ];
      when(() => mockRepository.getSeenStatus(1, MediaType.movie)).thenAnswer((_) async => viewings);
      when(() => mockRepository.removeFromSeen(any(), any(), 
          seasonNumber: any(named: 'seasonNumber'), 
          episodeNumber: any(named: 'episodeNumber'))).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove all viewings'));
      await tester.pumpAndSettle();

      expect(find.text('Remove all logs?'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.removeFromSeen(1, MediaType.movie)).called(1);
    });
  });
}
