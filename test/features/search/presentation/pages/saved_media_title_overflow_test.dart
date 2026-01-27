import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';

void main() {
  testWidgets('AppBar title Row overflows for very long text at small width', (WidgetTester tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
    binding.window.physicalSizeTestValue = const Size(360, 800);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    final longName = List.filled(200, 'A').join();

    await tester.pumpWidget(
      MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(longName),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Measure the rendered sizes of the title Row and the Text.
    final rowFinder = find.byType(Row);
    final textFinder = find.text(longName);

    // Ensure both widgets are present
    expect(rowFinder, findsOneWidget);
    expect(textFinder, findsOneWidget);

    final rowSize = tester.getSize(rowFinder);
    final textSize = tester.getSize(textFinder);

    // Assert that the text width fits within the AppBar title Row width (no overflow).
    // This assertion should fail on the unpatched layout and pass after we apply the fix.
    expect(textSize.width <= rowSize.width, isTrue,
        reason: 'Expected title text to fit within AppBar title width (no overflow)');
  });
}
