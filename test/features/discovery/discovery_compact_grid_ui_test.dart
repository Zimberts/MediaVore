import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/core/theme/app_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUp(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
    mockRepository = MockMediaRepository();
    final mockPrefs = MockSharedPreferences();

    // SharedPreferences stubs
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
      ),
    ).thenAnswer(
      (_) async => [
        MediaItem(
          id: 1,
          title: 'Tiny',
          overview: '',
          releaseDate: '2020-01-01',
          mediaType: MediaType.tv,
        ),
      ],
    );
    // Repository stubs for SearchProvider init
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockPrefs);
  });

  testWidgets('compact grid hides rating and meta when tile is small', (
    tester,
  ) async {
    // small logical width to force tight tiles
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;

    // Force large grid size so tiles are small
    settingsProvider.setGridSize(4);

    await settingsProvider.setGridSize(4);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const Scaffold(body: DiscoveryPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Rating/meta keys should not be present when tiles are compact
    expect(find.byKey(const ValueKey('meta-1-tv-grid')), findsNothing);
    expect(find.byKey(const ValueKey('notify-1-tv-grid')), findsNothing);
  });
}
