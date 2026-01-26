import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
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
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
    when(
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
  });

  testWidgets('SeenHistoryPage shows empty state when no seen items', (
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
          home: const SeenHistoryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Seen History'), findsOneWidget);
    expect(find.text('No items seen yet.'), findsOneWidget);
  });

  testWidgets('SeenHistoryPage displays entries when present', (tester) async {
    final seen = SeenItem(
      id: 1,
      tmdbId: 42,
      title: 'Test Movie',
      type: MediaType.movie,
      seenDate: DateTime.now(),
    );

    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => [seen]);

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
          home: const SeenHistoryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Movie'), findsOneWidget);
  });
}
