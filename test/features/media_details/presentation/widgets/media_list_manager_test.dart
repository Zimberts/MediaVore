import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/media_list_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;
  late MockSharedPreferences mockPrefs;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(
      const MediaItem(id: 1, title: 'T', overview: '', releaseDate: ''),
    );
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);

    settingsProvider = SettingsProvider(mockPrefs);

    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.markAsSeen(any()),
    ).thenAnswer((_) async => Future.value());

    searchProvider = SearchProvider(mockRepository);
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest({required String longListName}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MediaListManager(
            item: MediaItem(id: 1, title: 'T', overview: '', releaseDate: ''),
          ),
        ),
      ),
    );
  }

  testWidgets('does not throw overflow error for very long list names', (
    WidgetTester tester,
  ) async {
    // Make repository return a very long list name in addition to 'watchlist'
    final longName = List.filled(200, 'A').join();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', longName]);

    // Recreate provider to pick up the mocked names
    searchProvider = SearchProvider(mockRepository);

    await tester.pumpWidget(createWidgetUnderTest(longListName: longName));
    // Allow asynchronous provider initialization to complete
    await tester.pumpAndSettle();

    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason:
          'Expected no overflow or layout exceptions when rendering long list names',
    );
  });
}
