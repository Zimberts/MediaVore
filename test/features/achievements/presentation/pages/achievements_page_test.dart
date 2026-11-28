import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAchievementProvider provider;
  final navigatorKey = GlobalKey<NavigatorState>();

  // Enough standalone families for the last one to start off-screen.
  final achievements = [
    for (var i = 0; i < 30; i++)
      Achievement(
        id: 'a$i',
        title: 'Achievement $i',
        description: 'D$i',
        iconPath: 'I',
        category: 'movies',
      ),
  ];

  setUp(() {
    provider = MockAchievementProvider();
    when(() => provider.achievements).thenReturn(achievements);
    when(() => provider.families).thenReturn(groupAchievements(achievements));
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('fr'),
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AchievementProvider>.value(
        value: provider,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: navigatorKey,
          theme: const DefaultLightPalette().toThemeData(),
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
  }

  NavigatorState nav() => navigatorKey.currentState!;

  Future<void> show(WidgetTester tester, String id) async {
    AchievementsPage.showAchievement(nav(), id);
    await tester.pumpAndSettle();
  }

  group('AchievementsPage.showAchievement', () {
    testWidgets('should push the page when none is open', (tester) async {
      await pumpApp(tester);

      await show(tester, 'a0');

      expect(find.byType(AchievementsPage), findsOneWidget);
      expect(find.text('Achievement 0'), findsOneWidget);
    });

    testWidgets('should scroll the open page instead of pushing a second one', (
      tester,
    ) async {
      await pumpApp(tester);
      await show(tester, 'a0');
      expect(find.text('Achievement 29'), findsNothing);

      await show(tester, 'a29');

      expect(
        find.byType(AchievementsPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Achievement 29'), findsOneWidget);
      nav().pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('should pop back to the page when it is below another route', (
      tester,
    ) async {
      await pumpApp(tester);
      await show(tester, 'a0');
      nav().push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('other')),
        ),
      );
      await tester.pumpAndSettle();

      await show(tester, 'a29');

      expect(find.text('other', skipOffstage: false), findsNothing);
      expect(
        find.byType(AchievementsPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Achievement 29'), findsOneWidget);
    });

    testWidgets('should reuse a page opened without a target achievement', (
      tester,
    ) async {
      await pumpApp(tester);
      nav().push(AchievementsPage.route());
      await tester.pumpAndSettle();

      await show(tester, 'a29');

      expect(
        find.byType(AchievementsPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Achievement 29'), findsOneWidget);
    });

    testWidgets('groups families by category and hides empty categories', (
      tester,
    ) async {
      final categorizedAchievements = [
        const Achievement(
          id: 'm1',
          title: 'Movie Fan',
          description: 'Watch a movie',
          iconPath: 'I',
          group: 'movies_fam',
          groupTitle: 'Movies Fam',
          category: 'movies',
          tier: 1,
        ),
        const Achievement(
          id: 't1',
          title: 'TV Fan',
          description: 'Watch an episode',
          iconPath: 'I',
          group: 'tv_fam',
          groupTitle: 'TV Fam',
          category: 'tv',
          tier: 1,
        ),
        const Achievement(
          id: 'd1',
          title: 'Explorer',
          description: 'Watch international title',
          iconPath: 'I',
          group: 'disc_fam',
          groupTitle: 'Discovery Fam',
          category: 'discovery',
          tier: 1,
        ),
      ];

      when(() => provider.achievements).thenReturn(categorizedAchievements);
      when(
        () => provider.families,
      ).thenReturn(groupAchievements(categorizedAchievements));

      await pumpApp(tester);
      nav().push(AchievementsPage.route());
      await tester.pumpAndSettle();

      // Category headers for non-empty categories in French
      expect(find.text('Films'), findsOneWidget);
      expect(find.text('Séries'), findsOneWidget);
      expect(find.text('Découverte'), findsOneWidget);

      // Empty categories should NOT be displayed
      expect(find.text('Livres'), findsNothing);
      expect(find.text('Ensemble'), findsNothing);
      expect(find.text('Régularité'), findsNothing);
    });

    testWidgets(
      'displays pastille and tier dots for tiered family, and opens sheet with progressLabel',
      (tester) async {
        final unlockedDate = DateTime(2026, 3, 15);
        final tieredAchievements = [
          Achievement(
            id: 'f1',
            title: 'Tier One',
            description: 'First step',
            iconPath: 'I',
            group: 'my_fam',
            groupTitle: 'My Family',
            category: 'movies',
            tier: 1,
            isUnlocked: true,
            unlockedAt: unlockedDate,
          ),
          const Achievement(
            id: 'f2',
            title: 'Tier Two',
            description: 'Second step',
            iconPath: 'I',
            group: 'my_fam',
            category: 'movies',
            tier: 2,
            progress: 0.5,
            progressLabel: '5 / 10 movies',
          ),
          const Achievement(
            id: 'f3',
            title: 'Tier Three',
            description: 'Third step',
            iconPath: 'I',
            group: 'my_fam',
            category: 'movies',
            tier: 3,
          ),
        ];

        when(() => provider.achievements).thenReturn(tieredAchievements);
        when(
          () => provider.families,
        ).thenReturn(groupAchievements(tieredAchievements));

        await pumpApp(tester);
        nav().push(AchievementsPage.route());
        await tester.pumpAndSettle();

        // Card title reflects level: "Niveau 1 · My Family"
        expect(find.text('Niveau 1 · My Family'), findsOneWidget);

        // Pastille "1/3" is displayed
        expect(find.text('1/3'), findsOneWidget);

        // Next level progress label is shown on the card
        expect(find.text('Suivant : Tier Two · 5 / 10 movies'), findsOneWidget);

        // Tap on the card to open tiers sheet
        await tester.tap(find.text('Niveau 1 · My Family'));
        await tester.pumpAndSettle();

        // In the bottom sheet:
        // Tier 1 has unlocked date
        expect(find.text('Niveau 1 · Tier One'), findsOneWidget);
        expect(find.textContaining('2026'), findsWidgets);

        // Tier 2 has progress label '5 / 10 movies'
        expect(find.text('Niveau 2 · Tier Two'), findsOneWidget);
        expect(find.text('5 / 10 movies'), findsOneWidget);

        // Tier 3 has no progress label
        expect(find.text('Niveau 3 · Tier Three'), findsOneWidget);
      },
    );

    testWidgets(
      'should mask locked hidden achievements as ??? and exclude them from visible totals',
      (tester) async {
        final unlockedDate = DateTime(2026, 4);
        final mixed = [
          Achievement(
            id: 'vis_unlocked',
            title: 'Visible Unlocked',
            description: 'Done',
            iconPath: 'I',
            category: 'movies',
            isUnlocked: true,
            unlockedAt: unlockedDate,
          ),
          const Achievement(
            id: 'vis_locked',
            title: 'Visible Locked',
            description: 'Not done yet',
            iconPath: 'I',
            category: 'movies',
            progress: 0.4,
            progressLabel: '4 / 10',
          ),
          const Achievement(
            id: 'hid_locked',
            title: 'Secret Title',
            description: 'Secret Description',
            iconPath: 'I',
            category: 'regularity',
            isHidden: true,
            progress: 0.8,
            progressLabel: '8 / 10 secret',
          ),
        ];

        when(() => provider.achievements).thenReturn(mixed);
        when(() => provider.families).thenReturn(groupAchievements(mixed));

        await pumpApp(tester);
        nav().push(AchievementsPage.route());
        await tester.pumpAndSettle();

        // Visible totals exclude the locked hidden achievement: 1 of 2 badges, 1 / 2 challenges
        expect(find.text('Vous avez débloqué 1 badges sur 2'), findsOneWidget);
        expect(find.text('1 / 2 défis terminés'), findsOneWidget);

        // Hidden locked achievement shows ??? for title & description, masks progress
        expect(find.text('Secret Title'), findsNothing);
        expect(find.text('Secret Description'), findsNothing);
        expect(find.text('8 / 10 secret'), findsNothing);
        expect(find.text('???'), findsNWidgets(2));
        expect(find.byIcon(Icons.help_outline), findsOneWidget);

        // Visible achievements remain unaffected
        expect(find.text('Visible Unlocked'), findsOneWidget);
        expect(find.text('Visible Locked'), findsOneWidget);
        expect(find.text('4 / 10'), findsOneWidget);
      },
    );

    testWidgets(
      'should display unlocked hidden achievements normally and count them in totals',
      (tester) async {
        final unlockedDate = DateTime(2026, 12, 25);
        final list = [
          const Achievement(
            id: 'vis_locked',
            title: 'Visible Locked',
            description: 'Not done',
            iconPath: 'I',
            category: 'movies',
          ),
          Achievement(
            id: 'hid_unlocked',
            title: 'Christmas Movie',
            description: 'Watch on Dec 25',
            iconPath: 'I',
            category: 'regularity',
            isHidden: true,
            isUnlocked: true,
            unlockedAt: unlockedDate,
          ),
        ];

        when(() => provider.achievements).thenReturn(list);
        when(() => provider.families).thenReturn(groupAchievements(list));

        await pumpApp(tester);
        nav().push(AchievementsPage.route());
        await tester.pumpAndSettle();

        expect(find.text('Vous avez débloqué 1 badges sur 2'), findsOneWidget);
        expect(find.text('1 / 2 défis terminés'), findsOneWidget);
        expect(find.text('Christmas Movie'), findsOneWidget);
        expect(find.text('Watch on Dec 25'), findsOneWidget);
        expect(find.text('???'), findsNothing);
      },
    );

    testWidgets(
      'should mask locked hidden tiers in a partially unlocked tiered family',
      (tester) async {
        final unlockedDate = DateTime(2026, 12, 25);
        final tieredSecret = [
          Achievement(
            id: 's1',
            title: 'Secret One',
            description: 'First secret',
            iconPath: 'I',
            group: 'secret_fam',
            groupTitle: 'Secret Family',
            category: 'regularity',
            tier: 1,
            isHidden: true,
            isUnlocked: true,
            unlockedAt: unlockedDate,
          ),
          const Achievement(
            id: 's2',
            title: 'Secret Two',
            description: 'Second secret',
            iconPath: 'I',
            group: 'secret_fam',
            category: 'regularity',
            tier: 2,
            isHidden: true,
            progress: 0.5,
            progressLabel: '1 / 2 years',
          ),
        ];

        when(() => provider.achievements).thenReturn(tieredSecret);
        when(
          () => provider.families,
        ).thenReturn(groupAchievements(tieredSecret));

        await pumpApp(tester);
        nav().push(AchievementsPage.route());
        await tester.pumpAndSettle();

        // Card shows unlocked tier 1, does not leak tier 2 title or progress
        expect(find.text('Niveau 1 · Secret Family'), findsOneWidget);
        expect(find.textContaining('Secret Two'), findsNothing);
        expect(find.text('1 / 2 years'), findsNothing);

        // Open tiers bottom sheet
        await tester.tap(find.text('Niveau 1 · Secret Family'));
        await tester.pumpAndSettle();

        // Tier 1 is visible, Tier 2 is masked as ??? without progress
        expect(find.text('Niveau 1 · Secret One'), findsOneWidget);
        expect(find.text('Niveau 2 · Secret Two'), findsNothing);
        expect(find.text('1 / 2 years'), findsNothing);
        expect(find.text('???'), findsNWidgets(2));
      },
    );
  });
}
