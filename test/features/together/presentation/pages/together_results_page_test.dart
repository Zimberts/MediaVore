import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/together/presentation/pages/together_results_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;
  late SearchProvider searchProvider;
  late TogetherSessionProvider sessionProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() async {
    repo = MockMediaRepository();
    when(() => repo.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(
      () => repo.getWatchlistEntries(),
    ).thenAnswer((_) async => ['101:movie', '102:movie', '103:movie']);
    when(
      () => repo.getListEntries('watchlist'),
    ).thenAnswer((_) async => ['101:movie', '102:movie', '103:movie']);
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

    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => repo);

    when(
      () => repo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer(
      (invocation) async => MediaDetails(
        item: MediaItem(
          id: invocation.positionalArguments[0] as int,
          title: 'Movie ${invocation.positionalArguments[0]}',
          overview: 'Overview',
          releaseDate: '2023-01-01',
          mediaType:
              invocation.namedArguments[#type] as MediaType? ?? MediaType.movie,
          voteAverage: 8.0,
        ),
        cast: const [],
      ),
    );

    searchProvider = SearchProvider(repo);
    await searchProvider.loadLists();

    sessionProvider = TogetherSessionProvider();
  });

  Widget buildSubject() {
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
        home: const TogetherResultsPage(),
      ),
    );
  }

  group('TogetherResultsPage', () {
    testWidgets('displays common items between host and participant', (
      tester,
    ) async {
      sessionProvider.addParticipant(
        const TogetherParticipant(
          name: 'Alice',
          entries: [
            SharedMediaEntry(101, MediaType.movie),
            SharedMediaEntry(102, MediaType.movie),
            SharedMediaEntry(999, MediaType.movie),
          ],
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Common: 101 and 102
      expect(find.textContaining('2 en commun'), findsOneWidget);
      expect(find.text('Movie 101'), findsOneWidget);
      expect(find.text('Movie 102'), findsOneWidget);
      expect(find.text('Movie 999'), findsNothing);
    });

    testWidgets('shows Almost section for N >= 3 participants', (tester) async {
      // Host has 101, 102, 103
      // Alice has 101, 102
      // Bob has 101, 103
      sessionProvider.addParticipant(
        const TogetherParticipant(
          name: 'Alice',
          entries: [
            SharedMediaEntry(101, MediaType.movie),
            SharedMediaEntry(102, MediaType.movie),
          ],
        ),
      );
      sessionProvider.addParticipant(
        const TogetherParticipant(
          name: 'Bob',
          entries: [
            SharedMediaEntry(101, MediaType.movie),
            SharedMediaEntry(103, MediaType.movie),
          ],
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // In all 3: 101
      expect(find.text('Movie 101'), findsOneWidget);

      // In 2 of 3: 102 (host + Alice) and 103 (host + Bob)
      // Almost section header: "Presque : dans 2 listes sur 3"
      expect(
        find.textContaining('Presque : dans 2 listes sur 3'),
        findsOneWidget,
      );
      expect(find.text('Movie 102'), findsOneWidget);
      expect(find.text('Movie 103'), findsOneWidget);
    });

    testWidgets('shows vote limit banner when > 6 common items', (
      tester,
    ) async {
      final manyEntries = List.generate(
        8,
        (i) => SharedMediaEntry(100 + i, MediaType.movie),
      );

      when(() => repo.getWatchlistEntries()).thenAnswer(
        (_) async => manyEntries.map((e) => '${e.id}:${e.type.name}').toList(),
      );
      when(() => repo.getListEntries('watchlist')).thenAnswer(
        (_) async => manyEntries.map((e) => '${e.id}:${e.type.name}').toList(),
      );
      await searchProvider.loadWatchlist();

      sessionProvider.addParticipant(
        TogetherParticipant(name: 'Alice', entries: manyEntries),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('8 en commun'), findsOneWidget);
      expect(
        find.textContaining(
          'Le vote porte sur les 6 titres les mieux notés (sur 8)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when no common items', (tester) async {
      sessionProvider.addParticipant(
        const TogetherParticipant(
          name: 'Alice',
          entries: [SharedMediaEntry(999, MediaType.movie)],
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Aucun titre en commun'), findsWidgets);
    });

    testWidgets(
      'random pick opens dialog and "On le regarde !" navigates to details',
      (tester) async {
        sessionProvider.addParticipant(
          const TogetherParticipant(
            name: 'Alice',
            entries: [SharedMediaEntry(101, MediaType.movie)],
          ),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Tap random pick button
        await tester.tap(find.byKey(const Key('together_random_pick_button')));
        await tester.pumpAndSettle();

        // Dialog opens
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Movie 101'), findsWidgets);
        expect(find.text('On le regarde !'), findsOneWidget);

        // Tap "On le regarde !"
        await tester.tap(find.text('On le regarde !'));
        await tester.pumpAndSettle();

        // Navigates to detail page and session is reset
        expect(find.byType(MediaDetailPage), findsOneWidget);
        expect(sessionProvider.hasSession, isFalse);
      },
    );

    testWidgets('swipe vote button triggers startVote on session', (
      tester,
    ) async {
      sessionProvider.addParticipant(
        const TogetherParticipant(
          name: 'Alice',
          entries: [SharedMediaEntry(101, MediaType.movie)],
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(sessionProvider.isVoting, isFalse);
      await tester.tap(find.byKey(const Key('together_swipe_vote_button')));
      await tester.pumpAndSettle();

      expect(sessionProvider.isVoting, isTrue);
    });

    testWidgets(
      'handles fetch failure with Unknown fallback during parallel details fetch',
      (tester) async {
        when(
          () => repo.getMediaDetails(999, type: any(named: 'type')),
        ).thenThrow(Exception('TMDB network error'));

        sessionProvider.addParticipant(
          const TogetherParticipant(
            name: 'Alice',
            entries: [
              SharedMediaEntry(101, MediaType.movie),
              SharedMediaEntry(999, MediaType.movie),
            ],
          ),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('Movie 101'), findsWidgets);
      },
    );
  });
}
