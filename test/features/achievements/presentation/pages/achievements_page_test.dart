import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
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
      ),
  ];

  setUp(() {
    provider = MockAchievementProvider();
    when(() => provider.achievements).thenReturn(achievements);
    when(() => provider.families).thenReturn(groupAchievements(achievements));
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AchievementProvider>.value(
        value: provider,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: DefaultLightPalette().toThemeData(),
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
  });
}
