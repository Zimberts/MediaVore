import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/profile/presentation/pages/profile_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  group('ProfilePage pure helpers', () {
    test('countActiveDaysInLast30Days counts distinct days within 30 days', () {
      final now = DateTime(2026, 11, 16, 12, 0);

      // Items: 2 on today, 1 on 10 days ago, 1 on 29 days ago, 1 on 35 days ago (excluded)
      final items = [
        SeenItem(
          tmdbId: 1,
          type: MediaType.movie,
          title: 'A',
          seenDate: DateTime(2026, 11, 16, 9, 0),
        ),
        SeenItem(
          tmdbId: 2,
          type: MediaType.movie,
          title: 'B',
          seenDate: DateTime(2026, 11, 16, 20, 0),
        ),
        SeenItem(
          tmdbId: 3,
          type: MediaType.tv,
          title: 'C',
          seenDate: DateTime(2026, 11, 6, 15, 0),
        ),
        SeenItem(
          tmdbId: 4,
          type: MediaType.movie,
          title: 'D',
          seenDate: DateTime(2026, 10, 18, 12, 0),
        ),
        SeenItem(
          tmdbId: 5,
          type: MediaType.movie,
          title: 'Old',
          seenDate: DateTime(2026, 10, 5, 12, 0), // 42 days ago
        ),
      ];

      final count = countActiveDaysInLast30Days(items, referenceTime: now);
      expect(count, 3);
    });

    test(
      'selectPreviewAchievements returns 3 unlocked and 1 closest locked',
      () {
        const u1 = Achievement(
          id: 'u1',
          title: 'U1',
          description: 'D1',
          iconPath: '',
          isUnlocked: true,
        );
        const u2 = Achievement(
          id: 'u2',
          title: 'U2',
          description: 'D2',
          iconPath: '',
          isUnlocked: true,
        );
        const u3 = Achievement(
          id: 'u3',
          title: 'U3',
          description: 'D3',
          iconPath: '',
          isUnlocked: true,
        );
        const u4 = Achievement(
          id: 'u4',
          title: 'U4',
          description: 'D4',
          iconPath: '',
          isUnlocked: true,
        );
        const lLow = Achievement(
          id: 'l1',
          title: 'L1',
          description: 'D',
          iconPath: '',
          isUnlocked: false,
          progress: 0.2,
        );
        const lHigh = Achievement(
          id: 'l2',
          title: 'L2',
          description: 'D',
          iconPath: '',
          isUnlocked: false,
          progress: 0.85,
        );

        final selected = selectPreviewAchievements([
          u1,
          u2,
          u3,
          u4,
          lLow,
          lHigh,
        ]);
        expect(selected, hasLength(4));
        // First 3 are unlocked
        expect(selected.take(3).every((a) => a.isUnlocked), isTrue);
        // 4th is the locked with highest progress
        expect(selected.last.id, 'l2');
        expect(selected.last.progress, 0.85);
      },
    );

    test(
      'selectPreviewAchievements fills with locked when fewer than 3 unlocked',
      () {
        const u1 = Achievement(
          id: 'u1',
          title: 'U1',
          description: 'D1',
          iconPath: '',
          isUnlocked: true,
        );
        const l1 = Achievement(
          id: 'l1',
          title: 'L1',
          description: 'D',
          iconPath: '',
          isUnlocked: false,
          progress: 0.9,
        );
        const l2 = Achievement(
          id: 'l2',
          title: 'L2',
          description: 'D',
          iconPath: '',
          isUnlocked: false,
          progress: 0.7,
        );
        const l3 = Achievement(
          id: 'l3',
          title: 'L3',
          description: 'D',
          iconPath: '',
          isUnlocked: false,
          progress: 0.5,
        );

        final selected = selectPreviewAchievements([u1, l1, l2, l3]);
        expect(selected, hasLength(4));
        expect(selected.first.id, 'u1');
        expect(selected[1].id, 'l1');
        expect(selected[2].id, 'l2');
        expect(selected[3].id, 'l3');
      },
    );

    test('formatMaskedTmdbKey reveals only last 4 characters', () {
      expect(formatMaskedTmdbKey(''), '');
      expect(formatMaskedTmdbKey('1234'), '••••1234');
      expect(formatMaskedTmdbKey('abcdef0123456789'), '••••6789');
    });
  });

  group('ProfilePage Widget Tests', () {
    late MockMediaRepository mockRepository;
    late MockSharedPreferences mockSharedPreferences;
    late MockAchievementProvider mockAchievementProvider;
    late SearchProvider searchProvider;

    setUp(() async {
      mockRepository = MockMediaRepository();
      mockSharedPreferences = MockSharedPreferences();
      mockAchievementProvider = MockAchievementProvider();

      when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
      when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
      when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

      when(
        () => mockRepository.getAllListNames(),
      ).thenAnswer((_) async => ['watchlist']);
      when(
        () => mockRepository.getListEntries(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => []);
      when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
      when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);

      final now = DateTime.now();
      final seenList = [
        SeenItem(
          tmdbId: 101,
          type: MediaType.movie,
          title: 'Movie One',
          runtime: 120,
          seenDate: now.subtract(const Duration(days: 2)),
        ),
        SeenItem(
          tmdbId: 102,
          type: MediaType.movie,
          title: 'Movie Two',
          runtime: 90,
          seenDate: now.subtract(const Duration(days: 1)),
        ),
        SeenItem(
          tmdbId: 201,
          type: MediaType.tv,
          title: 'Series One',
          seasonNumber: 1,
          episodeNumber: 1,
          runtime: 45,
          seenDate: now.subtract(const Duration(days: 1)),
        ),
        SeenItem(
          tmdbId: 201,
          type: MediaType.tv,
          title: 'Series One',
          seasonNumber: 1,
          episodeNumber: 2,
          runtime: 45,
          seenDate: now,
        ),
      ];

      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => seenList);

      const achievementsList = [
        Achievement(
          id: 'a1',
          title: 'First Movie',
          description: 'Watch a movie',
          iconPath: '',
          isUnlocked: true,
        ),
        Achievement(
          id: 'a2',
          title: 'Ten Movies',
          description: 'Watch 10 movies',
          iconPath: '',
          isUnlocked: true,
        ),
        Achievement(
          id: 'a3',
          title: 'Night Owl',
          description: 'Watch at night',
          iconPath: '',
          isUnlocked: true,
        ),
        Achievement(
          id: 'a4',
          title: 'Marathon',
          description: 'Watch 5 in a day',
          iconPath: '',
          isUnlocked: false,
          progress: 0.6,
          progressLabel: '3/5',
        ),
      ];
      when(
        () => mockAchievementProvider.achievements,
      ).thenReturn(achievementsList);
      when(() => mockAchievementProvider.families).thenReturn([]);

      searchProvider = SearchProvider(mockRepository);
      await searchProvider.loadAllSeenStatus();
    });

    Widget createWidgetUnderTest({
      required SettingsProvider settingsProvider,
      Locale locale = const Locale('fr'),
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
          ChangeNotifierProvider<AchievementProvider>.value(
            value: mockAchievementProvider,
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: DefaultLightPalette().toThemeData(),
          home: const ProfilePage(),
        ),
      );
    }

    testWidgets('renders key figures identical to stats on Tout', (
      tester,
    ) async {
      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore('abc12345'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 2 movies, 2 episodes, total runtime 300 minutes = 5 hours
      expect(find.text('2'), findsNWidgets(2)); // 2 movies, 2 episodes
      expect(find.text('Films vus'), findsOneWidget);
      expect(find.text('Épisodes et écran'), findsOneWidget);
      expect(find.text('5 h d\'écran'), findsOneWidget);
    });

    testWidgets('displays active days in subtitle', (tester) async {
      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore('abc12345'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3 distinct days: today, yesterday, 2 days ago
      expect(find.text('3 jours actifs sur les 30 derniers'), findsOneWidget);
    });

    testWidgets('displays masked TMDB key revealing only last 4 characters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore('secret_api_key_9876'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pumpAndSettle();

      final tmdbTile = find.byKey(const Key('profile_tmdb_credential'));
      expect(tmdbTile, findsOneWidget);
      expect(
        find.descendant(of: tmdbTile, matching: find.text('••••9876')),
        findsOneWidget,
      );
      expect(find.text('secret_api_key_9876'), findsNothing);
    });

    testWidgets('displays Not set when TMDB key is empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore(''),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pumpAndSettle();

      final tmdbTile = find.byKey(const Key('profile_tmdb_credential'));
      expect(tmdbTile, findsOneWidget);
      expect(
        find.descendant(of: tmdbTile, matching: find.text('Non défini')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Toutes les statistiques navigates to MediaStatsPage', (
      tester,
    ) async {
      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore('key'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_stats')));
      await tester.pumpAndSettle();

      expect(find.byType(MediaStatsPage), findsOneWidget);
    });

    testWidgets('tapping Tout voir navigates to AchievementsPage', (
      tester,
    ) async {
      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore('key'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_achievements')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AchievementsPage), findsOneWidget);
    });

    testWidgets('tapping Paramètres navigates to SettingsPage', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore('key'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('profile_settings'));
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('tapping Identifiant TMDB navigates to TmdbCredentialPage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final settings = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore('key'),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(settingsProvider: settings),
      );
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('profile_tmdb_credential'));
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(TmdbCredentialPage), findsOneWidget);
    });

    testWidgets(
      'tapping Stockage et données navigates to DataCacheSettingsPage',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final settings = SettingsProvider(
          mockSharedPreferences,
          FakeTmdbCredentialStore('key'),
        );

        await tester.pumpWidget(
          createWidgetUnderTest(settingsProvider: settings),
        );
        await tester.pumpAndSettle();

        final tile = find.byKey(const Key('profile_storage'));
        await tester.tap(tile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(DataCacheSettingsPage), findsOneWidget);
      },
    );
  });
}
