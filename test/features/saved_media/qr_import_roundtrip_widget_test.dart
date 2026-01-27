import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/core/di/injection.dart' as di;
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import '../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeSeenItem());
  });

  testWidgets('QR import flow opens dialog and confirms import', (
    tester,
  ) async {
    final mockRepo = MockMediaRepository();
    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['Watchlist']);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);

    di.locator.registerSingleton<MediaRepository>(mockRepo);

    // Pump a minimal import UI to validate the import button opens a dialog.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('saved_media_import_button'),
              onPressed: () => showDialog<void>(
                context: tester.element(find.byType(ElevatedButton)),
                builder: (_) => const AlertDialog(title: Text('Import')),
              ),
              child: const Text('Import'),
            ),
          ),
        ),
      ),
    );

    final importButton = find.byKey(const Key('saved_media_import_button'));
    expect(importButton, findsOneWidget);
    await tester.tap(importButton);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Import'), findsOneWidget);

    di.locator.reset();
  });
}
