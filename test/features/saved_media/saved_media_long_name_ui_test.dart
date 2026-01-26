import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long list name is displayed without overflow', (tester) async {
    const longName =
        'This is a very long list name that should be truncated or ellipsized in the UI so it does not overflow the layout and cause errors or visual issues';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListTile(
            title: const Text(
              longName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    // The text should be present and not throw layout overflow
    expect(
      find.textContaining('This is a very long list name'),
      findsOneWidget,
    );
  });
}
