import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/empty_state.dart';
import 'package:mediavore/features/discovery/presentation/pages/swiper_page.dart';
import 'package:mediavore/features/discovery/presentation/widgets/swipe_card.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/providers/swiper_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

class FakeTmdbCredentialStore extends Fake implements TmdbCredentialStore {
  @override
  String get credential => '';
}

void main() {
  late MockMediaRepository repo;
  late MockSharedPreferences prefs;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  late SwiperProvider swiperProvider;

  final movie1 = const MediaItem(
    id: 101,
    title: 'Inception',
    overview: 'Dream within a dream',
    releaseDate: '2010-07-16',
    voteAverage: 8.8,
    mediaType: MediaType.movie,
  );

  final movie2 = const MediaItem(
    id: 102,
    title: 'Interstellar',
    overview: 'Space exploration',
    releaseDate: '2014-11-07',
    voteAverage: 8.6,
    mediaType: MediaType.movie,
  );

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(movie1);
    registerFallbackValue(
      SwipeDecisionModel(
        tmdbId: 0,
        title: '',
        decision: 'added',
        decidedAt: DateTime.now(),
      ),
    );
  });

  setUp(() async {
    repo = MockMediaRepository();
    prefs = MockSharedPreferences();

    when(() => prefs.getInt(any())).thenReturn(null);
    when(() => prefs.getDouble(any())).thenReturn(null);
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.getString(any())).thenReturn(null);
    when(() => prefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => prefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => prefs.setString(any(), any())).thenAnswer((_) async => true);

    when(
      () => repo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', 'Favorites']);
    when(() => repo.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => repo.getListEntries(any())).thenAnswer((_) async => []);
    when(
      () => repo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenItems()).thenAnswer((_) async => []);
    when(() => repo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repo.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => repo.getQuickAddItems()).thenAnswer((_) async => []);
    when(
      () => repo.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());

    when(() => repo.getDecidedTmdbIds()).thenAnswer((_) async => <int>{});
    when(
      () => repo.getSwipeDecisions(),
    ).thenAnswer((_) async => <SwipeDecisionModel>[]);
    when(
      () => repo.discoverMedia(
        type: any(named: 'type'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => [movie1, movie2]);

    when(
      () => repo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer(
      (inv) async => MediaDetails(
        item: inv.positionalArguments[0] == 101 ? movie1 : movie2,
        cast: const [],
      ),
    );

    when(() => repo.addToList(any(), any())).thenAnswer((_) async {});
    when(
      () => repo.removeFromList(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => repo.recordSwipeDecision(any())).thenAnswer((_) async {});
    when(() => repo.recordSwipeDecisions(any())).thenAnswer((_) async {});
    when(() => repo.undoLastSwipeDecision()).thenAnswer((_) async => null);

    searchProvider = SearchProvider(repo);
    await searchProvider.loadListNames();
    await searchProvider.loadWatchlist();
    await searchProvider.loadAllSeenStatus();

    settingsProvider = SettingsProvider(prefs, FakeTmdbCredentialStore());
    swiperProvider = SwiperProvider(repo);
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultDarkPalette().toThemeData(),
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppMessageHost(child: child!),
        home: SwiperPage(customSwiperProvider: swiperProvider),
      ),
    );
  }

  testWidgets('displays candidate movie and target list dropdown', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Swiper'), findsOneWidget);
    expect(
      find.byKey(const Key('swiper_target_list_dropdown')),
      findsOneWidget,
    );
    expect(find.byType(SwipeCard), findsOneWidget);
    expect(find.text('Inception'), findsOneWidget);
    expect(find.byKey(const Key('swiper_add_button')), findsOneWidget);
    expect(find.byKey(const Key('swiper_discard_button')), findsOneWidget);
    expect(find.byKey(const Key('swiper_undo_button')), findsOneWidget);
  });

  testWidgets('tapping Add button adds movie and advances to next candidate', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swiper_add_button')));
    await tester.pumpAndSettle();

    verify(() => repo.addToList(movie1, 'watchlist')).called(1);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('1 ajoutés · 0 écartés'), findsOneWidget);
  });

  testWidgets('tapping Discard button ignores movie and advances card', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swiper_discard_button')));
    await tester.pumpAndSettle();

    verifyNever(() => repo.addToList(any(), any()));
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('0 ajoutés · 1 écartés'), findsOneWidget);
  });

  testWidgets('tapping Undo button calls undoLastDecision', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    when(() => repo.undoLastSwipeDecision()).thenAnswer(
      (_) async => SwipeDecisionModel(
        isarId: 1,
        tmdbId: 101,
        title: 'Inception',
        decision: 'added',
        decidedAt: DateTime.now(),
        targetList: 'watchlist',
      ),
    );

    await tester.tap(find.byKey(const Key('swiper_add_button')));
    await tester.pumpAndSettle();

    // Tap Undo on the swiper action bar
    final undoButton = find.byKey(const Key('swiper_undo_button'));
    expect(undoButton, findsOneWidget);
    await tester.tap(undoButton);
    await tester.pumpAndSettle();

    verify(() => repo.undoLastSwipeDecision()).called(1);
    expect(find.text('Inception'), findsOneWidget);
  });

  testWidgets(
    'buttons remain immediately clickable without snackbar hit test overlay (#379)',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Inception'), findsOneWidget);

      // First tap adds Inception
      await tester.tap(find.byKey(const Key('swiper_add_button')));
      await tester.pump();

      // Second consecutive tap on swiper_add_button immediately adds Interstellar
      // without hit test obstruction from an AppMessageHost overlay
      await tester.tap(find.byKey(const Key('swiper_add_button')));
      await tester.pumpAndSettle();

      verify(() => repo.addToList(movie1, 'watchlist')).called(1);
      verify(() => repo.addToList(movie2, 'watchlist')).called(1);
      expect(find.text('2 ajoutés · 0 écartés'), findsOneWidget);
    },
  );

  testWidgets('displays empty state when all candidates are swiped', (
    tester,
  ) async {
    when(
      () => repo.discoverMedia(
        type: any(named: 'type'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Plus de films'), findsOneWidget);
  });

  testWidgets(
    'SwiperPage does not dispose injected customSwiperProvider when unmounted',
    (tester) async {
      when(
        () => repo.discoverMedia(
          type: any(named: 'type'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Unmount SwiperPage
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();

      // Injected swiperProvider must not be disposed
      void dummyListener() {}
      expect(() {
        swiperProvider.addListener(dummyListener);
        swiperProvider.removeListener(dummyListener);
      }, returnsNormally);
    },
  );
}
