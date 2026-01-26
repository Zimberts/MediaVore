import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => <SeenItem>[]);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => <NotifiedItem>[]);
    when(() => mockRepository.discoverMedia(page: any(named: 'page'), type: any(named: 'type'), genreIds: any(named: 'genreIds'), releaseYear: any(named: 'releaseYear'), minRating: any(named: 'minRating'))).thenAnswer((_) async => <MediaItem>[]);
    when(() => mockRepository.refreshNotifiedItems()).thenAnswer((_) async => {});
  });

  testWidgets('Toggles metric icon between entries and runtime', (tester) async {
    final seenItems = <SeenItem>[
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'Movie A',
        seenDate: DateTime(2024, 10, 1),
        runtime: 120,
      ),
    ];

    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => seenItems);

    final provider = SearchProvider(mockRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<SearchProvider>.value(value: provider)],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const MediaStatsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially should show history icon (entries)
    expect(find.byIcon(Icons.history), findsOneWidget);

    // Tap the toggle (use tooltip)
    final toggle = find.byTooltip('Toggle Metric (Logs/Time)');
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // After toggle, should show timer icon (runtime)
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
  });
}
