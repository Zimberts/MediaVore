import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
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
  });

  setUp(() {
    mockRepository = MockMediaRepository();
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
    when(() => mockRepository.markAsSeen(any())).thenAnswer((_) async => Future.value());

    searchProvider = SearchProvider(mockRepository);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: searchProvider,
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: Scaffold(
          body: SeenManager(
            item: MediaItem(
              id: 1,
              title: 'Inception',
              overview: 'Dream within a dream',
              releaseDate: '2010-07-16',
              mediaType: MediaType.movie,
            ),
          ),
        ),
      ),
    );
  }

  group('Seen Date Selection Pop-up', () {
    testWidgets('shows CalendarDatePicker by default', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.byIcon(Icons.keyboard), findsOneWidget); // Switch to text entry button
    });

    testWidgets('switches to text entry mode when keyboard icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Date (DD/MM/YYYY)'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget); // Switch back to calendar button
    });

    testWidgets('allows picking time via TimePicker', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      // Tap the Time row/button
      await tester.tap(find.textContaining('Time:'));
      await tester.pumpAndSettle();

      // Verify TimePickerDialog is shown (this is a system dialog)
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('logs viewing with selected date and time', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      // Select a specific day (e.g., 15th of the current month)
      // Note: This assumes 15 is visible on the calendar
      await tester.tap(find.text('15').first);
      await tester.pump();

      await tester.tap(find.text('LOG VIEWING'));
      await tester.pumpAndSettle();

      // Verify markAsSeen was called
      verify(() => mockRepository.markAsSeen(any())).called(1);
    });
  });
}
