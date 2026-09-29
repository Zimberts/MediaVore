import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/widgets/top_scrim_gradient.dart';

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      theme: DefaultLightPalette().toThemeData(),
      home: Scaffold(body: child),
    );
  }

  LinearGradient gradientOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(TopScrimGradient),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.gradient! as LinearGradient;
  }

  testWidgets(
    'fades the scaffold background colour from opaque to transparent top-to-bottom',
    (WidgetTester tester) async {
      final theme = DefaultLightPalette().toThemeData();

      await tester.pumpWidget(createWidgetUnderTest(const TopScrimGradient()));

      final gradient = gradientOf(tester);
      final bg = theme.scaffoldBackgroundColor;

      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(gradient.colors.length, 3);
      expect(gradient.colors.first, bg.withValues(alpha: 1.0));
      expect(gradient.colors.last, bg.withValues(alpha: 0.0));
    },
  );

  testWidgets('honours an explicit colour and height', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        const TopScrimGradient(color: Colors.red, height: 200),
      ),
    );

    final gradient = gradientOf(tester);

    expect(gradient.colors.first, Colors.red.withValues(alpha: 1.0));
    expect(gradient.colors.last, Colors.red.withValues(alpha: 0.0));

    final containerFinder = find.descendant(
      of: find.byType(TopScrimGradient),
      matching: find.byType(Container),
    );
    expect(tester.getSize(containerFinder).height, 200);
  });
}
