import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_saga.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSearchProvider extends Mock implements SearchProvider {}

void main() {
  group('MediaDetailSaga', () {
    late MockSearchProvider mockSearchProvider;

    const tFilm1 = MediaItem(
      id: 101,
      title: 'The Fellowship of the Ring',
      overview: 'First adventure',
      releaseDate: '2001-12-19',
      collectionId: 119,
      collectionName: 'The Lord of the Rings Collection',
    );

    const tFilm2 = MediaItem(
      id: 102,
      title: 'The Two Towers',
      overview: 'Second adventure',
      releaseDate: '2002-12-18',
      collectionId: 119,
      collectionName: 'The Lord of the Rings Collection',
    );

    const tFilm3 = MediaItem(
      id: 103,
      title: 'The Return of the King',
      overview: 'Final adventure',
      releaseDate: '2003-12-17',
      collectionId: 119,
      collectionName: 'The Lord of the Rings Collection',
    );

    const tFilmUpcoming = MediaItem(
      id: 104,
      title: 'The Hunt for Gollum',
      overview: 'Upcoming film',
      releaseDate: '2026-12-18',
      collectionId: 119,
      collectionName: 'The Lord of the Rings Collection',
    );

    setUpAll(() {
      registerFallbackValue(MediaType.movie);
      registerFallbackValue(
        const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
      );
      registerFallbackValue(<MediaItem>[]);
    });

    setUp(() {
      mockSearchProvider = MockSearchProvider();
      when(() => mockSearchProvider.listNames).thenReturn(['watchlist']);
      when(
        () => mockSearchProvider.isItemInList(any(), any()),
      ).thenReturn(false);
      when(() => mockSearchProvider.getSeenCount(any())).thenReturn(0);
      when(
        () => mockSearchProvider.addAllToList(any(), any()),
      ).thenAnswer((_) async {});
    });

    /// Marks [items] as seen in the global history held by the provider.
    void stubSeen(List<MediaItem> items) {
      for (final item in items) {
        when(() => mockSearchProvider.getSeenCount(item)).thenReturn(1);
      }
    }

    Widget buildWidget({
      required MediaItem currentItem,
      List<MediaItem>? collection,
      ValueChanged<MediaItem>? onOpen,
      Locale locale = const Locale('fr'),
    }) {
      return ChangeNotifierProvider<SearchProvider>.value(
        value: mockSearchProvider,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr'), Locale('en')],
          theme: AppPalette.paper.toThemeData(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MediaDetailSaga(
                currentItem: currentItem,
                collection: collection,
                onOpen: onOpen ?? (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('should render nothing when the collection is null or empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(currentItem: tFilm1));
      expect(find.byType(MediaDetailSaga), findsOneWidget);
      expect(find.textContaining('Saga'), findsNothing);

      await tester.pumpWidget(
        buildWidget(currentItem: tFilm1, collection: const []),
      );
      expect(find.textContaining('Saga'), findsNothing);
    });

    testWidgets(
      'should display the saga title, seen counter and films in order',
      (tester) async {
        // Intentionally pass films out of order: Film 3, Film 1, Film 2
        final unsorted = [tFilm3, tFilm1, tFilm2];
        stubSeen([tFilm1]);

        await tester.pumpWidget(
          buildWidget(currentItem: tFilm2, collection: unsorted),
        );
        await tester.pumpAndSettle();

        // Header with saga name
        expect(
          find.text('Saga · The Lord of the Rings Collection'),
          findsOneWidget,
        );
        // Subtitle counter: 1 film vu sur 3
        expect(find.text('1 film vu sur 3'), findsOneWidget);

        // Film 1: has index 1, checkmark, not current
        expect(find.text('1'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // Film 2: has index 2, is current -> "Cette fiche"
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Cette fiche'), findsOneWidget);

        // Film 3: has index 3
        expect(find.text('3'), findsOneWidget);
      },
    );

    testWidgets('should propose only films neither seen nor listed', (
      tester,
    ) async {
      // Film 1 is seen
      stubSeen([tFilm1]);

      // Film 2 is already in watchlist
      when(
        () => mockSearchProvider.isItemInList(tFilm2, 'watchlist'),
      ).thenReturn(true);
      // Film 1 and Film 3 are not in watchlist
      when(
        () => mockSearchProvider.isItemInList(tFilm1, 'watchlist'),
      ).thenReturn(false);
      when(
        () => mockSearchProvider.isItemInList(tFilm3, 'watchlist'),
      ).thenReturn(false);

      await tester.pumpWidget(
        buildWidget(currentItem: tFilm1, collection: [tFilm1, tFilm2, tFilm3]),
      );
      await tester.pumpAndSettle();

      // Only Film 3 is neither seen nor in watchlist -> 1 missing film!
      final buttonFinder = find.text('Ajouter 1 film manquant à « À voir »');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify addAllToList was called with exactly [tFilm3]
      verify(
        () => mockSearchProvider.addAllToList([tFilm3], 'watchlist'),
      ).called(1);
    });

    testWidgets(
      'should hide the add missing button when all films are seen or listed',
      (tester) async {
        // All 3 films are seen
        stubSeen([tFilm1, tFilm2, tFilm3]);

        await tester.pumpWidget(
          buildWidget(
            currentItem: tFilm1,
            collection: [tFilm1, tFilm2, tFilm3],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.playlist_add), findsNothing);
        expect(find.textContaining('Ajouter'), findsNothing);
      },
    );

    testWidgets('should display the upcoming badge for an unreleased film', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(currentItem: tFilm1, collection: [tFilm1, tFilmUpcoming]),
      );
      await tester.pumpAndSettle();

      expect(find.text('À venir (2026)'), findsOneWidget);
    });

    testWidgets('should open another film on tap but not the current one', (
      tester,
    ) async {
      MediaItem? openedItem;

      await tester.pumpWidget(
        buildWidget(
          currentItem: tFilm1,
          collection: [tFilm1, tFilm2],
          onOpen: (item) => openedItem = item,
        ),
      );
      await tester.pumpAndSettle();

      // Tapping current film (tFilm1)
      await tester.tap(find.text('The Fellowship of the Ring'));
      await tester.pumpAndSettle();
      expect(openedItem, isNull);

      // Tapping other film (tFilm2)
      await tester.tap(find.text('The Two Towers'));
      await tester.pumpAndSettle();
      expect(openedItem, equals(tFilm2));
    });

    testWidgets('should format saga strings in English', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          currentItem: tFilm1,
          collection: [tFilm1, tFilm2, tFilm3],
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Saga · The Lord of the Rings Collection'),
        findsOneWidget,
      );
      expect(find.text('0 of 3 films seen'), findsOneWidget);
      expect(find.text('This title'), findsOneWidget);
      expect(find.text('Add 3 missing films to "Watchlist"'), findsOneWidget);
    });

    testWidgets(
      'should count every seen film of the saga from the global history, '
      'whatever detail page is open (#438)',
      (tester) async {
        // Films 1 and 2 are seen; the open detail page is the unseen film 3.
        stubSeen([tFilm1, tFilm2]);

        await tester.pumpWidget(
          buildWidget(
            currentItem: tFilm3,
            collection: [tFilm1, tFilm2, tFilm3],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('2 films vus sur 3'), findsOneWidget);
        // One seen badge per seen film, none on the current unseen film.
        expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
        // Only film 3 is missing, and it is the current one.
        expect(
          find.text('Ajouter 1 film manquant à « À voir »'),
          findsOneWidget,
        );
      },
    );

    testWidgets('should never propose an already seen film as missing (#438)', (
      tester,
    ) async {
      stubSeen([tFilm1, tFilm2]);

      await tester.pumpWidget(
        buildWidget(currentItem: tFilm1, collection: [tFilm1, tFilm2, tFilm3]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajouter 1 film manquant à « À voir »'));
      await tester.pumpAndSettle();

      verify(
        () => mockSearchProvider.addAllToList([tFilm3], 'watchlist'),
      ).called(1);
    });
  });
}
