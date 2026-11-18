import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/navigation/app_tab_bar.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/features/discovery/presentation/providers/swipe_session_provider.dart';
import 'package:mediavore/features/library/presentation/pages/library_page.dart';
import 'package:mediavore/features/home/presentation/pages/home_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/library/presentation/widgets/lists_overview.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/together/presentation/pages/together_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/profile/presentation/pages/profile_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late MockAchievementProvider mockAchievementProvider;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  late SwipeSessionProvider swipeSession;
  late TogetherSessionProvider togetherSession;
  late StreamController<Achievement> achievements;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
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
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => []);

    // Achievement Provider mocks
    when(() => mockAchievementProvider.achievements).thenReturn([]);
    achievements = StreamController<Achievement>.broadcast();
    when(
      () => mockAchievementProvider.onAchievementUnlocked,
    ).thenAnswer((_) => achievements.stream);
    when(() => mockRepository.getQuickAddItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.createList(any())).thenAnswer((_) async {});
    when(
      () => mockRepository.addToList(any(), any()),
    ).thenAnswer((_) async {});

    searchProvider = SearchProvider(mockRepository);
    swipeSession = SwipeSessionProvider();
    togetherSession = TogetherSessionProvider();
    settingsProvider = SettingsProvider(
      mockSharedPreferences,
      FakeTmdbCredentialStore('fake_api_key'),
    );

    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockRepository);

    if (locator.isRegistered<AchievementProvider>()) {
      locator.unregister<AchievementProvider>();
    }
    locator.registerLazySingleton<AchievementProvider>(
      () => mockAchievementProvider,
    );
  });

  tearDown(() {
    achievements.close();
    locator.reset();
  });

  Widget createWidgetUnderTest({Locale? locale, List<AppTab>? tabs}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AchievementProvider>.value(
          value: mockAchievementProvider,
        ),
        ChangeNotifierProvider<SwipeSessionProvider>.value(value: swipeSession),
        ChangeNotifierProvider<TogetherSessionProvider>.value(
          value: togetherSession,
        ),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainPage(tabs: tabs),
      ),
    );
  }

  Finder tabItem(AppTab tab) => find.descendant(
    of: find.byType(AppTabBar),
    matching: find.byKey(ValueKey(tab)),
  );

  Future<void> goTo(WidgetTester tester, AppTab tab) async {
    await tester.tap(tabItem(tab));
    await tester.pumpAndSettle();
  }

  List<String> tabLabels(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(AppTabBar),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data!)
      .toList();

  group('tabs', () {
    testWidgets(
      'should show the five tabs of the design in order, in English',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(tabLabels(tester), [
          'Home',
          'Discover',
          'Library',
          'Together',
          'Me',
        ]);
      },
    );

    testWidgets('should show the five tabs of the design in order, in French', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();

      expect(tabLabels(tester), [
        'Accueil',
        'Découvrir',
        'Bibliothèque',
        'Ensemble',
        'Moi',
      ]);
    });

    testWidgets('should open on Home', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(searchProvider.selectedTab, AppTab.home);
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
    });

    testWidgets('should switch to the tapped tab', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final pages = <AppTab, Type>{
        AppTab.discover: SearchPage,
        AppTab.library: LibraryPage,
        AppTab.together: TogetherPage,
        AppTab.me: ProfilePage,
        AppTab.home: HomePage,
      };
      for (final entry in pages.entries) {
        await goTo(tester, entry.key);
        expect(searchProvider.selectedTab, entry.key);
        expect(
          find.byType(entry.value).hitTestable(),
          findsOneWidget,
          reason: entry.key.name,
        );
        expect(tester.takeException(), isNull, reason: entry.key.name);
      }
    });

    testWidgets('should mark the active tab with a pill, in duo on Together', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      final colors = AppPalette.paper.toExtension();

      Color? pillOf(AppTab tab) =>
          (tester
                      .widget<Container>(
                        find.descendant(
                          of: tabItem(tab),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color;
      Color? labelColorOf(AppTab tab) => tester
          .widget<Text>(
            find.descendant(of: tabItem(tab), matching: find.byType(Text)),
          )
          .style
          ?.color;

      expect(pillOf(AppTab.home), colors.surface2);
      expect(labelColorOf(AppTab.home), colors.text);
      expect(pillOf(AppTab.together), isNull);
      expect(labelColorOf(AppTab.together), colors.text2);

      await goTo(tester, AppTab.together);
      expect(pillOf(AppTab.together), colors.duoBg);
      expect(labelColorOf(AppTab.together), colors.duo);
      expect(pillOf(AppTab.home), isNull);
    });

    testWidgets('should expose each tab to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(tabItem(AppTab.home)),
        matchesSemantics(
          label: 'Home',
          hint: 'Tab 1 of 5',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('should have no floating action button on any tab', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      for (final tab in AppTab.values) {
        await goTo(tester, tab);
        expect(find.byType(FloatingActionButton), findsNothing);
      }
    });

    testWidgets('should work without the Together tab', (tester) async {
      final tabs = AppTab.values.where((t) => t != AppTab.together).toList();
      await tester.pumpWidget(createWidgetUnderTest(tabs: tabs));
      await tester.pumpAndSettle();

      expect(tabLabels(tester), ['Home', 'Discover', 'Library', 'Me']);
      await goTo(tester, AppTab.me);
      expect(find.byType(ProfilePage).hitTestable(), findsOneWidget);

      // Asking for a tab that is not shown falls back to the first one.
      searchProvider.setSelectedTab(AppTab.together);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Five tabs on the narrowest supported phone (iPhone SE 1st gen, 320 dp).
    for (final locale in const [Locale('en'), Locale('fr')]) {
      testWidgets(
        'should fit the five tabs on a 320 dp wide phone in ${locale.languageCode}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(createWidgetUnderTest(locale: locale));
          await tester.pumpAndSettle();

          expect(tabLabels(tester), hasLength(5));
          for (final tab in AppTab.values) {
            await goTo(tester, tab);
            expect(tester.takeException(), isNull, reason: tab.name);
          }
        },
      );
    }
  });

  group('state kept across tabs', () {
    testWidgets('should keep the state of a tab when leaving and coming back', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await goTo(tester, AppTab.library);
      final listsState = tester.state(find.byType(ListsOverview));
      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();
      expect(find.byType(SeenHistoryPage).hitTestable(), findsOneWidget);

      await goTo(tester, AppTab.me);
      await goTo(tester, AppTab.library);

      // Same section, same page instances: nothing was rebuilt from scratch.
      expect(searchProvider.librarySection, LibrarySection.history);
      expect(find.byType(SeenHistoryPage).hitTestable(), findsOneWidget);
      expect(
        tester.state(find.byType(ListsOverview, skipOffstage: false)),
        same(listsState),
      );
    });

    testWidgets('should keep a swipe session through a tab round trip', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await goTo(tester, AppTab.discover);

      swipeSession.setFilter(MediaKind.series);
      swipeSession.record(
        SwipeDecision(
          mediaKey: '1:tv',
          kind: SwipeDecisionKind.added,
          at: DateTime(2026, 11, 14),
        ),
      );
      swipeSession.record(
        SwipeDecision(
          mediaKey: '2:tv',
          kind: SwipeDecisionKind.passed,
          at: DateTime(2026, 11, 14),
        ),
      );

      await goTo(tester, AppTab.home);
      await goTo(tester, AppTab.discover);

      final session = tester
          .element(find.byType(SearchPage))
          .read<SwipeSessionProvider>();
      expect(session, same(swipeSession));
      expect(session.filter, MediaKind.series);
      expect(session.addedCount, 1);
      expect(session.passedCount, 1);
      expect(session.canUndo, isTrue);
      expect(session.undo()?.mediaKey, '2:tv');
      expect(session.decisions.single.mediaKey, '1:tv');
    });

    testWidgets('should keep a Together session through a tab round trip', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await goTo(tester, AppTab.together);

      togetherSession.addParticipant(
        const TogetherParticipant(name: 'Lea', entries: ['1:movie', '2:tv']),
      );
      togetherSession.castVote('Lea', '1:movie');

      await goTo(tester, AppTab.library);
      await goTo(tester, AppTab.together);

      final session = tester
          .element(find.byType(TogetherPage))
          .read<TogetherSessionProvider>();
      expect(session, same(togetherSession));
      expect(session.participants.single.name, 'Lea');
      expect(session.participants.single.entries, ['1:movie', '2:tv']);
      expect(session.votes, {
        'Lea': {'1:movie'},
      });
    });

    testWidgets('should hide the tab bar while a Together vote is running', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await goTo(tester, AppTab.together);

      togetherSession.addParticipant(const TogetherParticipant(name: 'Lea'));
      togetherSession.startVote();
      await tester.pumpAndSettle();
      expect(find.byType(AppTabBar), findsNothing);
      expect(find.byType(TogetherPage).hitTestable(), findsOneWidget);

      togetherSession.endVote();
      await tester.pumpAndSettle();
      expect(find.byType(AppTabBar), findsOneWidget);
      // Leaving the vote keeps the participants.
      expect(togetherSession.participants, hasLength(1));
    });
  });

  group('Library tab', () {
    testWidgets('should show Lists and History behind a segment', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await goTo(tester, AppTab.library);

      expect(find.byType(AppSegmented<LibrarySection>), findsOneWidget);
      expect(find.byType(ListsOverview).hitTestable(), findsOneWidget);
      expect(find.byType(SeenHistoryPage).hitTestable(), findsNothing);

      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();
      expect(find.byType(SeenHistoryPage).hitTestable(), findsOneWidget);
      expect(find.byType(ListsOverview).hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should send the empty-state search action to Discover', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await goTo(tester, AppTab.library);
      await tester.tap(find.byKey(const ValueKey('library_list_watchlist')));
      await tester.pumpAndSettle();
      expect(find.byType(SavedMediaPage), findsOneWidget);

      await tester.tap(find.text('Search a movie or series').hitTestable());
      await tester.pumpAndSettle();

      expect(find.byType(SavedMediaPage), findsNothing);
      expect(searchProvider.selectedTab, AppTab.discover);
      expect(find.byType(SearchPage).hitTestable(), findsOneWidget);
    });
  });

  group('Together tab', () {
    testWidgets('should show a coming soon screen', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();
      await goTo(tester, AppTab.together);

      expect(find.text('Choisir à plusieurs arrive bientôt'), findsOneWidget);
    });
  });

  group('shared list deep link', () {
    const events = EventChannel('com.llfbandit.app_links/events');
    const messages = MethodChannel('com.llfbandit.app_links/messages');

    testWidgets('should open the import dialog, then the Library lists', (
      tester,
    ) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      MockStreamHandlerEventSink? sink;
      messenger.setMockMethodCallHandler(messages, (call) async => null);
      messenger.setMockStreamHandler(
        events,
        MockStreamHandler.inline(
          onListen: (args, eventSink) {
            sink = eventSink;
          },
        ),
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(messages, null);
        messenger.setMockStreamHandler(events, null);
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await goTo(tester, AppTab.library);
      await tester.tap(find.text('History').last);
      await goTo(tester, AppTab.me);

      sink!.success('mediavore://share?name=Weekend&items=1:movie');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incoming_list_import_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('incoming_list_import_button')));
      await tester.pumpAndSettle();

      expect(find.text('Import List'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Weekend'), findsOneWidget);

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.createList('Weekend')).called(1);
      expect(find.text('Import List'), findsNothing);
      expect(searchProvider.selectedTab, AppTab.library);
      expect(searchProvider.librarySection, LibrarySection.lists);
      expect(find.byType(ListsOverview).hitTestable(), findsOneWidget);
    });

    testWidgets('should open the import dialog for the initial link', (
      tester,
    ) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        messages,
        (call) async => call.method == 'getInitialLink'
            ? 'https://mediavore.app/share?name=Cinema&items=1:movie,2:tv'
            : null,
      );
      addTearDown(() => messenger.setMockMethodCallHandler(messages, null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incoming_list_import_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('incoming_list_import_button')));
      await tester.pumpAndSettle();

      expect(find.text('Import List'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Cinema'), findsOneWidget);
    });
  });

  group('achievement banner', () {
    const achievement = Achievement(
      id: 'first_movie',
      title: 'First steps',
      description: 'Watch a movie',
      iconPath: '',
    );

    for (final tab in [AppTab.home, AppTab.library, AppTab.me]) {
      testWidgets('should show an unlocked achievement on ${tab.name}', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();
        await goTo(tester, tab);

        achievements.add(achievement);
        await tester.pump();
        // Let the banner slide in.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Achievement Unlocked!'), findsOneWidget);
        expect(find.text('First steps'), findsOneWidget);
        // Below the status bar and the app bar, never over the tab bar.
        final banner = tester.getRect(find.text('First steps'));
        expect(banner.top, greaterThan(kToolbarHeight));
        expect(
          banner.bottom,
          lessThan(tester.getRect(find.byType(AppTabBar)).top),
        );
        expect(tester.takeException(), isNull);

        // Auto-dismissed after 4 s.
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('First steps'), findsNothing);
      });
    }
  });

  group('TMDB credential', () {
    testWidgets('first launch without a key shows the TMDB onboarding', (
      WidgetTester tester,
    ) async {
      settingsProvider = SettingsProvider(
        mockSharedPreferences,
        FakeTmdbCredentialStore(),
      );
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TmdbCredentialPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('tmdb_credential_skip')));
      await tester.pumpAndSettle();

      expect(find.byType(TmdbCredentialPage), findsNothing);
      expect(
        find.text(fallbackLocalizations.tmdbCredentialLater),
        findsOneWidget,
      );
    });

    test('should point to the Me tab, not to tabs that no longer exist', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final fr = lookupAppLocalizations(const Locale('fr'));

      expect(en.tmdbCredentialLater, contains('${en.navMe} › '));
      expect(en.tmdbCredentialLater, contains(en.settingsTmdbCredential));
      expect(fr.tmdbCredentialLater, contains('Moi › Identifiant d\'API TMDB'));
      for (final gone in ['My Lists', 'Seen', 'Alerts', 'Mes listes', 'Vus']) {
        expect(en.tmdbCredentialLater, isNot(contains(gone)));
        expect(fr.tmdbCredentialLater, isNot(contains(gone)));
      }
    });
  });

  group('Me tab', () {
    testWidgets('should group Stats, Achievements and Settings', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await goTo(tester, AppTab.me);

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byKey(const Key('profile_stats')), findsOneWidget);
      expect(find.byKey(const Key('profile_achievements')), findsOneWidget);
      expect(find.byKey(const Key('profile_settings')), findsOneWidget);
    });

    testWidgets('should not show a settings gear on any other tab', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      for (final tab in AppTab.values.where((t) => t != AppTab.me)) {
        await goTo(tester, tab);
        expect(find.byIcon(Icons.settings), findsNothing, reason: tab.name);
      }
    });
  });
}
