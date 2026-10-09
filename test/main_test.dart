import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/main.dart';

void main() {
  group('BootstrapperApp', () {
    testWidgets('should show the app once initialization succeeds', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        BootstrapperApp(
          initializer: () async => calls++,
          app: const Text('APP', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('Loading MediaVore...'), findsOneWidget);
      await tester.pump(); // post-frame callback
      await tester.pump(const Duration(milliseconds: 300));

      expect(calls, 1);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('should show a themed error screen and retry on failure', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        BootstrapperApp(
          initializer: () async {
            calls++;
            if (calls == 1) throw StateError('boom');
          },
          app: const Text('APP', textDirection: TextDirection.ltr),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MediaVore could not start'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // Raw exception is hidden behind the collapsed details tile.
      expect(find.textContaining('boom'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.text('Loading MediaVore...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));

      expect(calls, 2);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('should ignore retry taps while an attempt is running', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        BootstrapperApp(
          initializer: () async {
            calls++;
            throw StateError('boom');
          },
          app: const SizedBox(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Retry'));
      await tester.pump();
      // Loading screen replaces the button, so a second tap cannot land.
      expect(find.text('Retry'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));

      expect(calls, 2);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
