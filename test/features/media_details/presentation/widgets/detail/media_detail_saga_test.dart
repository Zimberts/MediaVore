import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_saga.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSearchProvider extends Mock implements SearchProvider {}

void main() {
  late MockSearchProvider mockSearchProvider;

  const tFilm1 = MediaItem(
    id: 101,
    title: 'The Fellowship of the Ring',
    overview: 'First adventure',
    releaseDate: '2001-12-19',
    mediaType: MediaType.movie,
    collectionId: 119,
    collectionName: 'The Lord of the Rings Collection',
  );

  const tFilm2 = MediaItem(
    id: 102,
    title: 'The Two Towers',
    overview: 'Second adventure',
    releaseDate: '2002-12-18',
    mediaType: MediaType.movie,
    collectionId: 119,
    collectionName: 'The Lord of the Rings Collection',
  );

  const tFilm3 = MediaItem(
    id: 103,
    title: 'The Return of the King',
    overview: 'Final adventure',
    releaseDate: '2003-12-17',
    mediaType: MediaType.movie,
    collectionId: 119,
    collectionName: 'The Lord of the Rings Collection',
  );

  const tFilmUpcoming = MediaItem(
    id: 104,
    title: 'The Hunt for Gollum',
    overview: 'Upcoming film',
    releaseDate: '2026-12-18',
    mediaType: MediaType.movie,
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
    when(() => mockSearchProvider.isItemInList(any(), any())).thenReturn(false);
    when(
      () => mockSearchProvider.addAllToList(any(), any()),
    ).thenAnswer((_) async {});
  });

  Widget buildWidget({
    required MediaItem currentItem,
    List<MediaItem>? collection,
    List<SeenItem> seenStatus = const [],
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
              seenStatus: seenStatus,
              onOpen: onOpen ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders SizedBox.shrink when collection is null or empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(currentItem: tFilm1, collection: null),
    );
    expect(find.byType(MediaDetailSaga), findsOneWidget);
    expect(find.textContaining('Saga'), findsNothing);

    await tester.pumpWidget(
      buildWidget(currentItem: tFilm1, collection: const []),
    );
    expect(find.textContaining('Saga'), findsNothing);
  });

  testWidgets('displays saga title, seen counter, and films in chronological order', (
    tester,
  ) async {
    // Intentionally pass films out of order: Film 3, Film 1, Film 2
    final unsorted = [tFilm3, tFilm1, tFilm2];
    final seen = [
      SeenItem(
        tmdbId: tFilm1.id,
        type: MediaType.movie,
        title: tFilm1.title,
        seenDate: DateTime(2020),
      ),
    ];

    await tester.pumpWidget(
      buildWidget(
        currentItem: tFilm2,
        collection: unsorted,
        seenStatus: seen,
      ),
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
  });

  testWidgets(
    'calculates missing films and button proposes to add 1 film on a trilogy with 1 seen and 1 in list',
    (tester) async {
      // Film 1 is seen
      final seen = [
        SeenItem(
          tmdbId: tFilm1.id,
          type: MediaType.movie,
          title: tFilm1.title,
          seenDate: DateTime(2020),
        ),
      ];

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
        buildWidget(
          currentItem: tFilm1,
          collection: [tFilm1, tFilm2, tFilm3],
          seenStatus: seen,
        ),
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
    },
  );

  testWidgets('hides add missing button when all films are seen or in list', (
    tester,
  ) async {
    // All 3 films are seen
    final seen = [
      SeenItem(
        tmdbId: tFilm1.id,
        type: MediaType.movie,
        title: tFilm1.title,
        seenDate: DateTime(2020),
      ),
      SeenItem(
        tmdbId: tFilm2.id,
        type: MediaType.movie,
        title: tFilm2.title,
        seenDate: DateTime(2021),
      ),
      SeenItem(
        tmdbId: tFilm3.id,
        type: MediaType.movie,
        title: tFilm3.title,
        seenDate: DateTime(2022),
      ),
    ];

    await tester.pumpWidget(
      buildWidget(
        currentItem: tFilm1,
        collection: [tFilm1, tFilm2, tFilm3],
        seenStatus: seen,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.playlist_add), findsNothing);
    expect(find.textContaining('Ajouter'), findsNothing);
  });

  testWidgets('displays upcoming badge for unreleased film', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        currentItem: tFilm1,
        collection: [tFilm1, tFilmUpcoming],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('À venir (2026)'), findsOneWidget);
  });

  testWidgets('tapping another film invokes onOpen, tapping current film does not', (
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

  testWidgets('English localization formats saga strings correctly', (
    tester,
  ) async {
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
}
