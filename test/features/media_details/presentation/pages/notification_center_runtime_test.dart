import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider provider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'T',
        seenDate: DateTime.now(),
      ),
    );
    registerFallbackValue(
      const MediaItem(id: 1, title: 'T', overview: '', releaseDate: ''),
    );
  });

  setUp(() {
    mockRepository = MockMediaRepository();

    when(() => mockRepository.getAllListNames())
        .thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any()))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenStatus(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockRepository.markAsSeen(any()))
        .thenAnswer((_) async => Future.value());

    provider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(MockSharedPreferences(), FakeTmdbCredentialStore());
  });

  testWidgets(
    'shows formatted runtime in the Releases tab when available',
    (WidgetTester tester) async {
      final now = DateTime.now().subtract(const Duration(days: 1));
      when(() => mockRepository.getNotifiedItems()).thenAnswer(
        (_) async => [
          NotifiedItem(
            tmdbId: 10,
            type: MediaType.movie,
            title: 'Movie10',
            releaseDate: now,
            runtime: 135,
          ),
        ],
      );

      await provider.loadNotifiedItems();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
          ],
          child: const MaterialApp(home: NotificationCenterPage()),
        ),
      );
      await tester.pumpAndSettle();

      // 135 minutes -> '2h 15m' via Formatters.formatRuntime
      expect(find.textContaining('2h 15m'), findsOneWidget);
    },
  );

  testWidgets(
    'shows no runtime suffix in the Releases tab when runtime is null',
    (WidgetTester tester) async {
      final now = DateTime.now().subtract(const Duration(days: 1));
      when(() => mockRepository.getNotifiedItems()).thenAnswer(
        (_) async => [
          NotifiedItem(
            tmdbId: 10,
            type: MediaType.movie,
            title: 'Movie10',
            releaseDate: now,
          ),
        ],
      );

      await provider.loadNotifiedItems();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
          ],
          child: const MaterialApp(home: NotificationCenterPage()),
        ),
      );
      await tester.pumpAndSettle();

      // No ' · runtime' separator should be rendered when runtime is absent.
      expect(find.textContaining('·'), findsNothing);
    },
  );

  testWidgets(
    'shows formatted runtime in the Quick Add tab when available',
    (WidgetTester tester) async {
      when(() => mockRepository.getQuickAddItems()).thenAnswer(
        (_) async => [
          QuickAddItem(
            tmdbId: 20,
            type: MediaType.tv,
            seasonNumber: 1,
            episodeNumber: 3,
            insertedAt: DateTime.now(),
            title: 'Show20',
            runtime: 45,
          ),
        ],
      );

      await provider.loadQuickAddItems();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
          ],
          child: const MaterialApp(home: NotificationCenterPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Add'));
      await tester.pumpAndSettle();

      // 45 minutes -> '45m' via Formatters.formatRuntime
      expect(find.textContaining('45m'), findsOneWidget);
    },
  );
}
