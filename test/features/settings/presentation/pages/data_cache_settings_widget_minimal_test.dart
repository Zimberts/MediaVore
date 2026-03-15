import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('minimal pump', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: Text('ok')))));
    await tester.pump();
    expect(find.text('ok'), findsOneWidget);
  });
}
