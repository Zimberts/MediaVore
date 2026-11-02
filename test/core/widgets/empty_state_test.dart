import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/widgets/empty_state.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('EmptyState', () {
    testWidgets('should show icon, title and message', (tester) async {
      await tester.pumpWidget(
        wrap(
          const EmptyState(
            icon: Icons.history,
            title: 'Nothing here',
            message: 'Add something.',
          ),
        ),
      );

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('should call onAction when the button is tapped', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          EmptyState(
            icon: Icons.bookmark_border,
            title: 'Empty list',
            actionLabel: 'Search',
            actionIcon: Icons.search,
            onAction: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      expect(taps, 1);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should hide the button without a callback', (tester) async {
      await tester.pumpWidget(
        wrap(
          const EmptyState(
            icon: Icons.notifications_none,
            title: 'No releases',
            actionLabel: 'Search',
          ),
        ),
      );

      expect(find.text('Search'), findsNothing);
    });

    testWidgets('should lay out inside a scrollable', (tester) async {
      await tester.pumpWidget(
        wrap(
          ListView(
            children: const [
              EmptyState(icon: Icons.notifications_none, title: 'No releases'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No releases'), findsOneWidget);
    });
  });
}
