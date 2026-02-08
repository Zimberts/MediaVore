import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() async {
    mockMediaRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

    when(() => mockMediaRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockMediaRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListEntries(any())).thenAnswer((_) async => ['1:movie']);
    when(() => mockMediaRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockMediaRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => mockMediaRepository.getSeenStatus(any(), any()))
      .thenAnswer((_) async => <SeenItem>[]);

    final item = const MediaItem(
      id: 1,
      title: 'Inception',
      overview: 'Overview',
      releaseDate: '2010',
      mediaType: MediaType.movie,
    );

    when(() => mockMediaRepository.getMediaDetails(1, type: MediaType.movie))
        .thenAnswer((_) async => MediaDetails(item: item, cast: []));

    searchProvider = SearchProvider(mockMediaRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    if (!locator.isRegistered<SearchProvider>()) {
      locator.registerSingleton<SearchProvider>(searchProvider);
    }
    if (!locator.isRegistered<MediaRepository>()) {
      locator.registerSingleton<MediaRepository>(mockMediaRepository);
    }
  });

  tearDown(() {
    locator.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: const SavedMediaPage(),
      ),
    );
  }

  testWidgets('tapping saved media opens details as bottom-sheet', (WidgetTester tester) async {
    // Ensure provider preloads
    await searchProvider.loadLikedStatus();

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);

    // Tap the title (which is an InkWell in the saved media card)
    await tester.tap(find.text('Inception'));
    await tester.pumpAndSettle();

    // Expect a DraggableScrollableSheet (our modal sheet) to be present
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });
}
