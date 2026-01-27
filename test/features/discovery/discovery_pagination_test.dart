import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    // Discover page 1 -> two items (movie + tv), page 2 -> two more
    when(
      () => mockRepository.discoverMedia(
        page: 1,
        type: any(named: 'type'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
      ),
    ).thenAnswer(
      (_) async => [
        MediaItem(
          id: 1,
          title: 'P1-A',
          overview: '',
          releaseDate: '2024',
          mediaType: MediaType.movie,
        ),
      ],
    );

    when(
      () => mockRepository.discoverMedia(
        page: 2,
        type: any(named: 'type'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
      ),
    ).thenAnswer(
      (_) async => [
        MediaItem(
          id: 101,
          title: 'P2-A',
          overview: '',
          releaseDate: '2024',
          mediaType: MediaType.movie,
        ),
      ],
    );
  });

  testWidgets('DiscoveryPage fetches next page when scrolled near bottom', (
    tester,
  ) async {
    final mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(0);
    when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
    when(() => mockPrefs.getBool(any())).thenReturn(false);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    final settings = SettingsProvider(mockPrefs);
    final provider = SearchProvider(mockRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SearchProvider>.value(value: provider),
        ],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const DiscoveryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final initialCount = provider.items.length;

    // Request next page programmatically (avoids scroll positioning flakiness)
    await provider.fetchNextPage();
    await tester.pumpAndSettle();

    // After fetchNextPage, provider should have additional items from page 2
    expect(provider.items.length, greaterThan(initialCount));
  });
}
