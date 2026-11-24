import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

QuickAddItemModel _queued(int tmdbId, int season, int episode) =>
    QuickAddItemModel(
      tmdbId: tmdbId,
      type: 'tv',
      seasonNumber: season,
      episodeNumber: episode,
      insertedAt: DateTime.utc(2025),
    );

QuickAddOptOutModel _optOut(int tmdbId, [int? season, int? episode]) =>
    QuickAddOptOutModel(
      tmdbId: tmdbId,
      seasonNumber: season,
      episodeNumber: episode,
      optedOutAt: DateTime.utc(2025, 2),
    );

void main() {
  late Isar isar;
  late MediaListLocalDataSource local;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_datasource_import_optouts';
    Directory(tempPath).createSync(recursive: true);
  });

  tearDownAll(() {
    final dir = Directory(tempPath);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [
        QuickAddItemModelSchema,
        QuickAddOptOutModelSchema,
        MediaListItemSchema,
        UserListSchema,
        SeenItemModelSchema,
        LikedItemSchema,
        NotifiedItemModelSchema,
      ],
      directory: tempPath,
      name: 'optouts_${DateTime.now().microsecondsSinceEpoch}',
    );
    local = MediaListLocalDataSource(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Future<List<(int, int?, int?)>> optOuts() async => [
    for (final o in await local.getOptOuts())
      (o.tmdbId, o.seasonNumber, o.episodeNumber),
  ]..sort((a, b) => a.$1.compareTo(b.$1));

  group('importAll opt-outs', () {
    test('should replace the opt-outs when mode is replace', () async {
      await local.addOptOut(1, seasonNumber: 1, episodeNumber: 2);

      await local.importAll(
        mode: ImportMode.replace,
        optOuts: [_optOut(2, 3, 4), _optOut(5)],
      );

      expect(await optOuts(), [(2, 3, 4), (5, null, null)]);
    });

    test('should add only the missing opt-outs when mode is merge', () async {
      await local.addOptOut(1, seasonNumber: 1, episodeNumber: 2);

      await local.importAll(
        mode: ImportMode.merge,
        optOuts: [_optOut(1, 1, 2), _optOut(1, 1, 2), _optOut(3, 1, 1)],
      );

      expect(await optOuts(), [(1, 1, 2), (3, 1, 1)]);
    });

    test('should drop the queued episodes an imported opt-out excludes, '
        'even when imported in the same archive', () async {
      await local.addQuickAddItem(_queued(10, 1, 2));
      await local.addQuickAddItem(_queued(20, 2, 1));

      await local.importAll(
        mode: ImportMode.merge,
        quickAdd: [_queued(30, 1, 5), _queued(40, 1, 1)],
        optOuts: [_optOut(10, 1, 2), _optOut(30)],
      );

      final queued = [for (final q in await local.getQuickAddItems()) q.tmdbId]
        ..sort();
      expect(queued, [20, 40]);
    });
  });
}
