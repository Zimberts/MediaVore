import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

import '../../helpers/mocks.dart';
import 'package:mediavore/core/theme/app_palette.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeSeenItem());
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
    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <MediaItem>[]);
    when(
      () => mockRepository.searchMedia(
        any(),
        page: any(named: 'page'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        language: any(named: 'language'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => <MediaItem>[]);
  });

  testWidgets(
    'Applying filters then searching calls repository with filter type',
    (tester) async {
      final mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getInt(any())).thenReturn(0);
      when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
      when(() => mockPrefs.getBool(any())).thenReturn(false);
      when(
        () => mockPrefs.setDouble(any(), any()),
      ).thenAnswer((_) async => true);
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

      // Open filter dialog
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Open the media type dropdown and select 'TV Shows'
      await tester.tap(find.byType(DropdownButton<MediaType?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('TV Shows').last);
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Open search input
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query (debounced 500ms in DiscoveryPage)
      await tester.enterText(find.byType(TextField).first, 'matrix');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify repository.searchMedia was called with type MediaType.tv
      verify(
        () => mockRepository.searchMedia(
          'matrix',
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          language: any(named: 'language'),
          type: MediaType.tv,
        ),
      ).called(1);
    },
  );
}
