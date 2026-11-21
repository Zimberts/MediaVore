import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/widgets/prompt_field.dart';

void main() {
  testWidgets('PromptField renders initial text and invokes onChanged', (
    tester,
  ) async {
    var changedValue = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromptField(
            initialText: 'Hello',
            label: 'Name',
            hint: 'Enter name',
            onChanged: (val) => changedValue = val,
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);

    await tester.enterText(find.byType(PromptField), 'World');
    expect(changedValue, 'World');
  });

  testWidgets('PromptField disposes internal controller without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromptField(initialText: 'Test', onChanged: (_) {}),
        ),
      ),
    );

    expect(find.byType(PromptField), findsOneWidget);

    // Unmount PromptField
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );

    expect(find.byType(PromptField), findsNothing);
  });
}
