import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.deleteSeenEntry(any())).thenAnswer((_) async => Future.value());
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const SeenHistoryPage(),
      ),
    );
  }

  group('Seen History UI Requirements', () {
    testWidgets('groups items by date', (WidgetTester tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Today Movie', seenDate: now),
        SeenItem(id: 2, tmdbId: 2, type: MediaType.movie, title: 'Yesterday Movie', seenDate: yesterday),
      ];
      
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => viewings);
      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for date headers
      expect(find.text(DateFormat.yMMMMEEEEd().format(now)), findsOneWidget);
      expect(find.text(DateFormat.yMMMMEEEEd().format(yesterday)), findsOneWidget);
    });

    testWidgets('swipe to delete shows red background and confirms', (WidgetTester tester) async {
      final now = DateTime.now();
      final viewings = [
        SeenItem(id: 1, tmdbId: 1, type: MediaType.movie, title: 'Delete Me', seenDate: now),
      ];
      
      // Track items locally so the mock reflects changes after delete is called
      var currentItems = List<SeenItem>.from(viewings);
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => currentItems);
      when(() => mockRepository.deleteSeenEntry(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as int;
        currentItems.removeWhere((item) => item.id == id);
      });

      await searchProvider.loadAllSeenStatus();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Swipe left - offset needs to be enough to trigger dismissal start
      await tester.drag(find.text('Delete Me'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Remove log?'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      // pumpAndSettle is important here to finish the dismissal animation and state update
      await tester.pumpAndSettle();

      verify(() => mockRepository.deleteSeenEntry(1)).called(1);
      expect(find.text('Delete Me'), findsNothing);
    });
  });
}
