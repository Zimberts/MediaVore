import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart'
    as repo_types;
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

class MockAchievementRepo extends Mock implements AchievementRepository {}

class MockRepo extends Mock implements MediaRepository {}

class MockSearchProvider extends Mock
    with ChangeNotifier
    implements SearchProvider {}

class MockAchievementProvider extends Mock
    with ChangeNotifier
    implements AchievementProvider {}

class FakeFilePicker extends FilePicker {
  Future<FilePickerResult?> Function({
    String? dialogTitle,
    String? initialDirectory,
    FileType? type,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool? allowCompression,
    int? compressionQuality,
    bool? allowMultiple,
    bool? withData,
    bool? withReadStream,
    bool? lockParentWindow,
    bool? readSequential,
  })?
  onPick;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    if (onPick != null) {
      return onPick!(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        onFileLoading: onFileLoading,
        allowCompression: allowCompression,
        compressionQuality: compressionQuality,
        allowMultiple: allowMultiple,
        withData: withData,
        withReadStream: withReadStream,
        lockParentWindow: lockParentWindow,
        readSequential: readSequential,
      );
    }
    return null;
  }
}

void main() {
  testWidgets('pump page with mocks', (tester) async {
    print('TEST START');
    registerFallbackValue(ImportMode.append);
    registerFallbackValue((double p, String s) {});

    final mockRepo = MockRepo();
    final mockAchievementRepo = MockAchievementRepo();

    when(
      () => mockAchievementRepo.getAchievements(),
    ).thenAnswer((_) async => <Achievement>[]);
    when(
      () => mockAchievementRepo.watchAchievements(),
    ).thenAnswer((_) => Stream<List<Achievement>>.value(<Achievement>[]));
    when(
      () => mockAchievementRepo.clearAchievements(),
    ).thenAnswer((_) async {});
    when(
      () => mockAchievementRepo.unlockAchievement(any(), any()),
    ).thenAnswer((_) async {});

    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getNotifiedItems(),
    ).thenAnswer((_) async => <repo_types.NotifiedItem>[]);
    when(() => mockRepo.getAllListNames()).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <repo_types.MediaItemPreview>[]);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepo.getQuickAddItems(),
    ).thenAnswer((_) async => <repo_types.QuickAddItem>[]);
    when(
      () => mockRepo.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.importAllData(
        any(),
        mode: any(named: 'mode'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async {});

    final provider = MockSearchProvider();
    when(() => provider.isCacheLoading).thenReturn(false);
    when(() => provider.isDbSizeLoading).thenReturn(false);
    when(() => provider.isImporting).thenReturn(false);
    when(() => provider.cacheSize).thenReturn(0);
    when(() => provider.seenDbSize).thenReturn(0);
    when(() => provider.importProgress).thenReturn(0.0);
    when(() => provider.importStatus).thenReturn('');
    when(
      () => provider.exportAllData(),
    ).thenAnswer((_) async => <int>[1, 2, 3]);
    when(
      () => provider.importAllData(any(), mode: any(named: 'mode')),
    ).thenAnswer((_) async {});

    final mockAchievementProvider = MockAchievementProvider();
    when(
      () => mockAchievementProvider.clearAchievements(),
    ).thenAnswer((_) async {});

    final mockFilePicker = FakeFilePicker();
    mockFilePicker.onPick =
        ({
          String? dialogTitle,
          String? initialDirectory,
          FileType? type,
          List<String>? allowedExtensions,
          Function(FilePickerStatus)? onFileLoading,
          bool? allowCompression,
          int? compressionQuality,
          bool? allowMultiple,
          bool? withData,
          bool? withReadStream,
          bool? lockParentWindow,
          bool? readSequential,
        }) async {
          return null;
        };
    FilePicker.platform = mockFilePicker;

    print('ABOUT TO PUMP WIDGET');
    await tester.pumpWidget(
      MaterialApp(
        theme: DefaultLightPalette().toThemeData(),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
            ChangeNotifierProvider<AchievementProvider>.value(
              value: mockAchievementProvider,
            ),
          ],
          child: const DataCacheSettingsPage(),
        ),
      ),
    );
    print('PUMPED');
    await tester.pump();
    print('DONE');
    expect(find.byType(DataCacheSettingsPage), findsOneWidget);
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
        theme: DefaultLightPalette().toThemeData(),
        home: ChangeNotifierProvider<SearchProvider>.value(
          value: provider,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final decodedBytes = <int>[1, 2, 3];
                      showDialog(
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
