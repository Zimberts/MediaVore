import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart'
    as repo_types;
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_file_picker.dart';
import '../../../../helpers/mocks.dart';

class MockAchievementRepo extends Mock implements AchievementRepository {}

class MockRepo extends Mock implements MediaRepository {}

class MockSearchProvider extends Mock
    with ChangeNotifier
    implements SearchProvider {}

class MockAchievementProvider extends Mock
    with ChangeNotifier
    implements AchievementProvider {}

void main() {
  testWidgets('pump page with mocks', (tester) async {
    registerFallbackValue(ImportMode.append);
    registerFallbackValue((double p, String s) {});

    final mockRepo = MockRepo();
    final mockAchievementRepo = MockAchievementRepo();

    when(
      mockAchievementRepo.getAchievements,
    ).thenAnswer((_) async => <Achievement>[]);
    when(
      mockAchievementRepo.watchAchievements,
    ).thenAnswer((_) => Stream<List<Achievement>>.value(<Achievement>[]));
    when(mockAchievementRepo.clearAchievements).thenAnswer((_) async {});
    when(
      () => mockAchievementRepo.unlockAchievement(any(), any()),
    ).thenAnswer((_) async {});

    when(mockRepo.getSeenItems).thenAnswer((_) async => <SeenItem>[]);
    when(mockRepo.getLikedEntries).thenAnswer((_) async => <String>[]);
    when(
      mockRepo.getNotifiedItems,
    ).thenAnswer((_) async => <repo_types.NotifiedItem>[]);
    when(mockRepo.getAllListNames).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <repo_types.MediaItemPreview>[]);
    when(mockRepo.getCacheSize).thenAnswer((_) async => 0);
    when(mockRepo.getSeenDbSize).thenAnswer((_) async => 0);
    when(
      mockRepo.getQuickAddItems,
    ).thenAnswer((_) async => <repo_types.QuickAddItem>[]);
    when(mockRepo.getWatchlistEntries).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.importAllData(
        any(),
        mode: any(named: 'mode'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async {});

    final provider = MockSearchProvider();
    final warmupProgress = ValueNotifier<CacheWarmupProgress?>(null);
    when(() => provider.cacheWarmupProgress).thenReturn(warmupProgress);
    when(provider.cancelCacheFill).thenReturn(null);
    when(() => provider.isCacheLoading).thenReturn(false);
    when(() => provider.isDbSizeLoading).thenReturn(false);
    when(() => provider.isImporting).thenReturn(false);
    when(() => provider.cacheSize).thenReturn(0);
    when(() => provider.seenDbSize).thenReturn(0);
    when(() => provider.importProgress).thenReturn(0.0);
    when(() => provider.importStatus).thenReturn('');
    when(provider.exportAllData).thenAnswer((_) async => <int>[1, 2, 3]);
    when(
      () => provider.importAllData(any(), mode: any(named: 'mode')),
    ).thenAnswer((_) async {});

    final mockAchievementProvider = MockAchievementProvider();
    when(mockAchievementProvider.clearAchievements).thenAnswer((_) async {});

    final settingsProvider = SettingsProvider(
      MockSharedPreferences(),
      FakeTmdbCredentialStore(),
    );

    FilePickerPlatform.instance = FakeFilePickerPlatform();

    await tester.pumpWidget(
      MaterialApp(
        theme: const DefaultLightPalette().toThemeData(),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider<AchievementProvider>.value(
              value: mockAchievementProvider,
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
          ],
          child: const DataCacheSettingsPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(DataCacheSettingsPage), findsOneWidget);
    expect(find.text('Fill Cache'), findsOneWidget);

    // A running warm-up shows its progress and can be cancelled.
    warmupProgress.value = const CacheWarmupProgress(3, 10);
    await tester.pump();
    expect(find.text('Fill Cache'), findsNothing);
    expect(find.text('Caching titles: 3 / 10'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.3, 1e-9));
    await tester.tap(find.text('Cancel'));
    verify(provider.cancelCacheFill).called(1);

    warmupProgress.value = null;
    await tester.pump();
    expect(find.text('Fill Cache'), findsOneWidget);
  });

  testWidgets('shows loading overlay when isImporting is true', (tester) async {
    final provider = MockSearchProvider();
    final warmupProgress = ValueNotifier<CacheWarmupProgress?>(null);
    when(() => provider.cacheWarmupProgress).thenReturn(warmupProgress);
    when(provider.cancelCacheFill).thenReturn(null);
    when(() => provider.isCacheLoading).thenReturn(false);
    when(() => provider.isDbSizeLoading).thenReturn(false);
    when(() => provider.isImporting).thenReturn(true);
    when(() => provider.cacheSize).thenReturn(0);
    when(() => provider.seenDbSize).thenReturn(0);
    when(() => provider.importProgress).thenReturn(0.5);
    when(() => provider.importStatus).thenReturn('Importing data...');

    final mockAchievementProvider = MockAchievementProvider();
    final settingsProvider = SettingsProvider(
      MockSharedPreferences(),
      FakeTmdbCredentialStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: const DefaultLightPalette().toThemeData(),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider<AchievementProvider>.value(
              value: mockAchievementProvider,
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
          ],
          child: const DataCacheSettingsPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Importing data...'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Import Preview dialog -> Merge calls provider.importAllData', (
    tester,
  ) async {
    final provider = MockSearchProvider();
    when(
      () => provider.importAllData(any(), mode: any(named: 'mode')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: const DefaultLightPalette().toThemeData(),
        home: ChangeNotifierProvider<SearchProvider>.value(
          value: provider,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final decodedBytes = <int>[1, 2, 3];
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Import Preview'),
                          content: const Text('Preview'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                await context
                                    .read<SearchProvider>()
                                    .importAllData(
                                      decodedBytes,
                                      mode: ImportMode.merge,
                                    );
                              },
                              child: const Text('Merge'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Import Preview'), findsOneWidget);
    await tester.tap(find.text('Merge'));
    await tester.pumpAndSettle();
    verify(
      () => provider.importAllData(any(), mode: ImportMode.merge),
    ).called(1);
  });
}
