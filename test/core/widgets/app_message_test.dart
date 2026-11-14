import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_sheet.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

import '../../helpers/pump_app.dart';

void main() {
  /// App with a tab bar, the way `main.dart` wires the host.
  Widget app({AppPalette palette = AppPalette.papier}) => testApp(
    Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home body')),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    ),
    palette: palette,
    scaffold: false,
    builder: (context, child) => AppMessageHost(child: child!),
  );

  NavigatorState navigator(WidgetTester tester) =>
      tester.state<NavigatorState>(find.byType(Navigator));

  Future<void> pushDetailPage(WidgetTester tester) async {
    navigator(tester).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Detail')),
          body: const Center(child: Text('Detail body')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
  }

  group('showAppMessage', () {
    for (final palette in testPalettes) {
      testWidgets(
        'should show at the bottom, above the tab bar, on ${palette.id.name}',
        (tester) async {
          await tester.pumpWidget(app(palette: palette));

          showAppMessage('List deleted');
          await tester.pump();

          final message = tester.getRect(find.text('List deleted'));
          final tabBar = tester.getRect(find.byType(BottomNavigationBar));
          final appBar = tester.getRect(find.byType(AppBar));
          expect(message.bottom, lessThanOrEqualTo(tabBar.top));
          expect(message.top, greaterThan(appBar.bottom));

          final colors = palette.toExtension();
          expect(
            tester.widget<Text>(find.text('List deleted')).style?.color,
            colors.bg,
          );
        },
      );
    }

    testWidgets('should disappear after 2.5 s without action', (tester) async {
      await tester.pumpWidget(app());

      showAppMessage('Saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('should stay 6 s with an action', (tester) async {
      await tester.pumpWidget(app());

      showAppMessage('Removed', actionLabel: 'Undo', onAction: () {});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5900));
      expect(find.text('Removed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Removed'), findsNothing);
    });

    testWidgets('should replace the message on screen and restart the timer', (
      tester,
    ) async {
      await tester.pumpWidget(app());

      showAppMessage('First');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      showAppMessage('Second');
      await tester.pump();
      expect(find.text('First'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Second'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('should run Undo from above an open detail page', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await pushDetailPage(tester);

      var undone = 0;
      showAppMessage(
        'Marked as seen',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      await tester.pump();

      // Visible and reachable over the pushed page.
      expect(find.text('Marked as seen').hitTestable(), findsOneWidget);
      final undo = find.widgetWithText(TextButton, 'Undo');
      expect(undo.hitTestable(), findsOneWidget);
      final size = tester.getSize(undo);
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));

      await tester.tap(undo);
      await tester.pump();
      expect(undone, 1);
      expect(find.text('Marked as seen'), findsNothing);
      expect(find.text('Detail body'), findsOneWidget);

      // The action runs once: nothing fires when the 6 s elapse.
      await tester.pump(const Duration(seconds: 7));
      expect(undone, 1);
    });

    testWidgets('should stay visible above an open sheet', (tester) async {
      await tester.pumpWidget(app());
      showAppSheet<void>(
        context: tester.element(find.text('Home body')),
        builder: (context) =>
            const SizedBox(height: 500, child: Text('Sheet content')),
      );
      await tester.pumpAndSettle();

      var undone = 0;
      showAppMessage('Removed', actionLabel: 'Undo', onAction: () => undone++);
      await tester.pump();

      final sheet = tester.getRect(find.byType(BottomSheet));
      final message = tester.getRect(find.text('Removed'));
      expect(sheet.contains(message.center), isTrue);
      expect(find.text('Removed').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(undone, 1);
      expect(find.text('Sheet content'), findsOneWidget);
    });

    testWidgets('should keep a message with an action for screen readers', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());

      showAppMessage('Removed', actionLabel: 'Undo', onAction: () {});
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Removed'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Removed')).flagsCollection.isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('should be dropped when no host is mounted', (tester) async {
      await tester.pumpWidget(testApp(const Text('No host')));

      showAppMessage('Lost');
      await tester.pump();
      expect(appMessageController.current, isNull);
      expect(find.text('Lost'), findsNothing);
    });
  });
}
