import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/together/presentation/models/together_vote_engine.dart';
import 'package:mediavore/features/together/presentation/pages/together_vote_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;
  late SearchProvider searchProvider;
  late TogetherSessionProvider sessionProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = MockMediaRepository();
    when(() => repo.getAllListNames()).thenAnswer((_) async => ['watchlist']);
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
    when(() => repo.getSeenStatus(any(), any())).thenAnswer((_) async => []);
    when(
      () => repo.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => repo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer(
      (inv) async => MediaDetails(
        item: MediaItem(
          id: inv.positionalArguments[0] as int,
          title: 'Movie ${inv.positionalArguments[0]}',
          overview: 'Overview',
          releaseDate: '2023-01-01',
          mediaType: inv.namedArguments[#type] as MediaType? ?? MediaType.movie,
          voteAverage: 8.0,
        ),
        cast: const [],
      ),
    );

    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => repo);

    searchProvider = SearchProvider(repo);
    sessionProvider = TogetherSessionProvider();
  });

  Widget buildSubject({
    required List<TogetherVoteCandidate> candidates,
    required List<String> participants,
    TogetherVoteEngine? engine,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: searchProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
      ],
      child: MaterialApp(
        theme: AppPalette.ink.toThemeData(),
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: AppMessageHost(
          child: TogetherVotePage(
            candidates: candidates,
            participants: participants,
            engine: engine,
          ),
        ),
      ),
    );
  }

  MediaItem createItem(int id, String title, {double rating = 8.0}) {
    return MediaItem(
      id: id,
      title: title,
      overview: 'Overview of $title',
      releaseDate: '2023-05-15',
      mediaType: MediaType.movie,
      voteAverage: rating,
    );
  }

  group('TogetherVotePage', () {
    testWidgets(
      'transitions from host prompt to voting cards, then friend transition',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final candidates = [
          TogetherVoteCandidate(item: createItem(1, 'Interstellar')),
          TogetherVoteCandidate(item: createItem(2, 'Inception')),
        ];
        final participants = ['Moi', 'Léa'];

        await tester.pumpWidget(
          buildSubject(candidates: candidates, participants: participants),
        );
        await tester.pumpAndSettle();

        // Host transition screen
        expect(find.text('À vous de voter'), findsOneWidget);
        expect(find.text('Je vote'), findsOneWidget);

        // Start host turn
        await tester.tap(find.byKey(const Key('together_start_turn_button')));
        await tester.pumpAndSettle();

        // Card 1: Interstellar
        expect(find.text('Interstellar'), findsOneWidget);
        expect(find.textContaining('Titre 1 sur 2'), findsOneWidget);
        expect(find.text('Moi'), findsOneWidget);

        // Vote Yes for Card 1
        await tester.tap(find.byKey(const Key('together_vote_yes')));
        await tester.pumpAndSettle();

        // Card 2: Inception
        expect(find.text('Inception'), findsOneWidget);
        expect(find.textContaining('Titre 2 sur 2'), findsOneWidget);

        // Vote No for Card 2
        await tester.tap(find.byKey(const Key('together_vote_no')));
        await tester.pumpAndSettle();

        // Next voter: Léa transition screen
        expect(find.text('Passez le téléphone à Léa'), findsOneWidget);
        expect(find.text('C\'est parti !'), findsOneWidget);
      },
    );

    testWidgets(
      'exit confirmation dialog intercepts back button and leaves on confirm',
      (tester) async {
        final candidates = [
          TogetherVoteCandidate(item: createItem(1, 'Interstellar')),
        ];
        final participants = ['Moi', 'Léa'];

        await tester.pumpWidget(
          buildSubject(candidates: candidates, participants: participants),
        );
        await tester.pumpAndSettle();

        // Tap close icon
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Dialog opens
        expect(find.text('Quitter le vote'), findsOneWidget);
        expect(
          find.textContaining('Les votes déjà donnés seront perdus'),
          findsOneWidget,
        );

        // Tap Quitter
        await tester.tap(find.text('Quitter'));
        await tester.pumpAndSettle();

        expect(sessionProvider.isVoting, isFalse);
      },
    );

    testWidgets('completes full vote and displays winner screen with results', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final candidates = [
        TogetherVoteCandidate(item: createItem(1, 'Interstellar', rating: 9.0)),
        TogetherVoteCandidate(item: createItem(2, 'Inception', rating: 8.8)),
      ];
      final participants = ['Moi', 'Léa'];

      final engine = TogetherVoteEngine(
        candidates: candidates,
        participants: participants,
      );

      // Host votes Yes for Interstellar, No for Inception
      engine.startTurn();
      engine.castVote(true);
      engine.castVote(false);

      // Léa votes Yes for Interstellar, Yes for Inception
      engine.startTurn();
      engine.castVote(true);
      engine.castVote(true);

      // Engine is now finished!
      expect(engine.isFinished, isTrue);

      await tester.pumpWidget(
        buildSubject(
          candidates: candidates,
          participants: participants,
          engine: engine,
        ),
      );
      await tester.pumpAndSettle();

      // Winner screen: Le choix du soir
      expect(find.text('Le choix du soir'), findsWidgets);
      // Interstellar won with 2 votes (unanimous!)
      expect(find.text('Interstellar'), findsOneWidget);
      expect(find.text('Unanimité !'), findsOneWidget);

      // Other titles: Inception (#2)
      expect(find.text('Autres titres'), findsOneWidget);
      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);

      // Action buttons
      expect(
        find.byKey(const Key('together_watch_this_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('together_review_list_button')),
        findsOneWidget,
      );

      // Tap "On le regarde !"
      await tester.tap(find.byKey(const Key('together_watch_this_button')));
      await tester.pumpAndSettle();

      // Navigates to detail page and session is reset
      expect(find.byType(MediaDetailPage), findsOneWidget);
      expect(sessionProvider.hasSession, isFalse);
    });

    testWidgets(
      'shows tie badge when winners have identical approvals and rating',
      (tester) async {
        final candidates = [
          TogetherVoteCandidate(item: createItem(1, 'Movie A', rating: 8.0)),
          TogetherVoteCandidate(item: createItem(2, 'Movie B', rating: 8.0)),
        ];
        final participants = ['Moi'];

        final engine = TogetherVoteEngine(
          candidates: candidates,
          participants: participants,
        );

        engine.startTurn();
        engine.castVote(true);
        engine.castVote(true);

        await tester.pumpWidget(
          buildSubject(
            candidates: candidates,
            participants: participants,
            engine: engine,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Égalité'), findsOneWidget);
      },
    );

    testWidgets(
      'TogetherVotePage does not dispose injected engine when unmounted',
      (tester) async {
        final candidates = [
          TogetherVoteCandidate(item: createItem(1, 'Movie A', rating: 8.0)),
        ];
        final engine = TogetherVoteEngine(
          candidates: candidates,
          participants: ['Moi'],
        );

        await tester.pumpWidget(
          buildSubject(
            candidates: candidates,
            participants: ['Moi'],
            engine: engine,
          ),
        );
        await tester.pumpAndSettle();

        // Unmount page
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pumpAndSettle();

        // Injected engine must not be disposed
        void dummyListener() {}
        expect(() {
          engine.addListener(dummyListener);
          engine.removeListener(dummyListener);
        }, returnsNormally);
      },
    );
  });
}
