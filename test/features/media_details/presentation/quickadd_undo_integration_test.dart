import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';

/// Minimal test-only repo that delegates to the local datasource.
class LocalTestRepo {
  final MediaListLocalDataSource local;

  LocalTestRepo(this.local);

  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await local.addOptOut(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    await local.removeQuickAddItemByTmdbSeasonEpisode(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  Future<void> clearOptOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await local.removeOptOut(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  Future<void> populateQuickAddFromSeenHistory() async {
    // For this integration test, simply re-add a known quick-add if missing.
    final existing = await local.getQuickAddItems();
    final exists = existing.any(
      (e) => e.tmdbId == 100 && e.seasonNumber == 1 && e.episodeNumber == 2,
    );
    if (!exists) {
      await local.addQuickAddItem(
        QuickAddItemModel(
          tmdbId: 100,
          type: 'tv',
          seasonNumber: 1,
          episodeNumber: 2,
          insertedAt: DateTime.now(),
          title: 'Test Show',
        ),
      );
    }
  }

  Future<void> removeQuickAddItemById(int isarId) async =>
      local.removeQuickAddItemById(isarId);
}

void main() {
  late Isar isar;
  late MediaListLocalDataSource local;
  late LocalTestRepo repo;
  late String tempPath;

  setUp(() async {
    // Avoid downloading native libs during CI/dev runs; change to 'true' if running on a clean machine.
    try {
      await Isar.initializeIsarCore(download: false);
    } catch (_) {}

    tempPath =
        '${Directory.current.path}/test/tmp_quickadd_integration_${DateTime.now().microsecondsSinceEpoch}';
    Directory(tempPath).createSync(recursive: true);

    isar = await Isar.open(
      [QuickAddItemModelSchema, QuickAddOptOutModelSchema],
      directory: tempPath,
      name: 'test_quickadd_db',
    );

    local = MediaListLocalDataSource(isar);
    repo = LocalTestRepo(local);
  });

  tearDown(() async {
    try {
      await isar.close(deleteFromDisk: true);
    } catch (_) {}
    try {
      if (Directory(tempPath).existsSync()) {
        Directory(tempPath).deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('isar quick-add opt-out and undo (non-widget)', () async {
    final qaModel = QuickAddItemModel(
      tmdbId: 100,
      type: 'tv',
      seasonNumber: 1,
      episodeNumber: 2,
      insertedAt: DateTime.now(),
      title: 'Test Show',
    );

    // Add quick-add
    await local.addQuickAddItem(qaModel).timeout(const Duration(seconds: 30));

    // Simulate opt-out via repo
    await repo
        .optOutSeries(100, seasonNumber: 1, episodeNumber: 2)
        .timeout(const Duration(seconds: 30));

    // Verify removal
    final remaining = await local.getQuickAddItems().timeout(
      const Duration(seconds: 10),
    );
    expect(remaining.where((e) => e.tmdbId == 100).isEmpty, isTrue);

    // Verify opt-out persisted
    final opted = await local
        .isOptedOut(100, seasonNumber: 1, episodeNumber: 2)
        .timeout(const Duration(seconds: 10));
    expect(opted, isTrue);

    // Clear opt-out and repopulate
    await repo
        .clearOptOutSeries(100, seasonNumber: 1, episodeNumber: 2)
        .timeout(const Duration(seconds: 10));
    await repo.populateQuickAddFromSeenHistory().timeout(
      const Duration(seconds: 30),
    );

    // Check restored
    final restored = await local.getQuickAddItems().timeout(
      const Duration(seconds: 10),
    );
    expect(
      restored
          .where(
            (e) =>
                e.tmdbId == 100 && e.seasonNumber == 1 && e.episodeNumber == 2,
          )
          .isNotEmpty,
      isTrue,
    );

    final stillOpted = await local
        .isOptedOut(100, seasonNumber: 1, episodeNumber: 2)
        .timeout(const Duration(seconds: 10));
    expect(stillOpted, isFalse);
  });
}
