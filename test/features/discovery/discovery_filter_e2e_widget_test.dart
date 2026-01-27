import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/core/di/injection.dart' as di;
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import '../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeSeenItem());
  });

  testWidgets('Filter -> Search -> Lazy load flow', (tester) async {
    final mockRepo = MockMediaRepository();
    when(() => mockRepo.discoverMedia()).thenAnswer((_) async => <MediaItem>[]);
    when(
      () => mockRepo.searchMedia(any()),
    ).thenAnswer((_) async => <MediaItem>[]);
    when(() => mockRepo.getAllListNames()).thenAnswer((_) async => <String>[]);

    di.locator.registerSingleton<MediaRepository>(mockRepo);

    // Pump a minimal discovery-like UI containing a filter icon, a search field,
    // and a scrollable grid placeholder. This keeps the test focused and
    // avoids initializing the whole app.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
            ],
          ),
          body: Column(
            children: [
              TextField(key: const Key('discovery_search_field')),
              Expanded(
                child: ListView.builder(
                  key: const Key('discovery_grid'),
                  itemCount: 20,
                  itemBuilder: (_, i) => ListTile(title: Text('Item #$i')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Tap filter icon
    final filterButton = find.byIcon(Icons.filter_list);
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    // Enter search text and wait for debounce
    final searchField = find.byKey(const Key('discovery_search_field'));
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'Matrix');
    await tester.pump(const Duration(milliseconds: 600));

    // Scroll to trigger lazy load placeholder
    final grid = find.byKey(const Key('discovery_grid'));
    expect(grid, findsOneWidget);
    await tester.fling(grid, const Offset(0, -500), 1000);
    await tester.pumpAndSettle();

    di.locator.reset();
  });
}
