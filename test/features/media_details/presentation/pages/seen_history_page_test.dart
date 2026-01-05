import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late SearchProvider searchProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    searchProvider = SearchProvider(mockMediaRepository);
    locator.registerSingleton<MediaRepository>(mockMediaRepository);
    
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
        home: SeenHistoryPage(),
      ),
    );
  }

  testWidgets('displays empty message when no items seen', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No items seen yet.'), findsOneWidget);
  });

  testWidgets('displays grouped list of seen items', (WidgetTester tester) async {
    final seenDate = DateTime(2023, 10, 1);
    final seenItems = [
      SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Movie A', seenDate: seenDate),
      SeenItem(id: 2, tmdbId: 2, type: MediaType.tv, title: 'Show B', seenDate: seenDate, seasonNumber: 1, episodeNumber: 1),
    ];

    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => seenItems);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Movie A'), findsOneWidget);
    expect(find.text('Show B'), findsOneWidget);
    // Check group header
    expect(find.textContaining('October 1, 2023'), findsOneWidget);
  });

  testWidgets('swiping to delete shows confirmation and calls delete', (WidgetTester tester) async {
    final seenDate = DateTime(2023, 10, 1);
    final seenItems = [
      SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Movie A', seenDate: seenDate),
    ];

    // Initial state: 1 item
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => seenItems);
    when(() => mockMediaRepository.deleteSeenEntry(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Movie A'), findsOneWidget);

    // Swipe to delete
    await tester.drag(find.text('Movie A'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Remove log?'), findsOneWidget);

    // After deletion is confirmed, getSeenItems should return empty
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);

    // Confirm
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    verify(() => mockMediaRepository.deleteSeenEntry(1)).called(1);
    expect(find.text('Movie A'), findsNothing);
  });
}
