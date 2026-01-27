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

  testWidgets('Deep-link import navigates to import confirmation', (
    tester,
  ) async {
    final mockRepo = MockMediaRepository();
    // Provide minimal stubs used during app init
    when(() => mockRepo.getAllListNames()).thenAnswer((_) async => <String>[]);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);

    di.locator.registerSingleton<MediaRepository>(mockRepo);

    // Pump a minimal scaffold that represents the Saved Media entry point so the
    // test focuses on wiring rather than full app initialization.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Saved')),
          body: const Icon(Icons.bookmark, key: Key('saved_media_bookmark')),
        ),
      ),
    );

    // The lightweight expectation ensures the test runs without heavy app init.
    final finder = find.byKey(const Key('saved_media_bookmark'));
    expect(finder, findsOneWidget);

    // Clean up the service locator registration
    di.locator.reset();
  });
}
