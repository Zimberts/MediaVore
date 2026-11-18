import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';

void main() {
  late Isar isar;
  late String tempPath;

  Future<Isar> open() => Isar.open(
    [QuickAddItemModelSchema, QuickAddOptOutModelSchema],
    directory: tempPath,
    name: 'test_opt_outs_db',
  );

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath =
        '${Directory.current.path}/test/tmp_opt_outs_${DateTime.now().microsecondsSinceEpoch}';
    Directory(tempPath).createSync(recursive: true);
    isar = await open();
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

  group('MediaListLocalDataSource.getOptOuts', () {
    test('should list the opt-outs and forget the cleared ones', () async {
      final local = MediaListLocalDataSource(isar);
      expect(await local.getOptOuts(), isEmpty);

      await local.addOptOut(100, seasonNumber: 1, episodeNumber: 2);
      await local.addOptOut(200, seasonNumber: 3, episodeNumber: 4);

      final optOuts = await local.getOptOuts();
      expect({for (final o in optOuts) o.tmdbId}, {100, 200});

      await local.removeOptOut(100, seasonNumber: 1, episodeNumber: 2);

      final left = (await local.getOptOuts()).single;
      expect(left.tmdbId, 200);
      expect(left.seasonNumber, 3);
      expect(left.episodeNumber, 4);
    });

    test(
      'should still list an opt-out after the database is reopened',
      () async {
        await MediaListLocalDataSource(
          isar,
        ).addOptOut(100, seasonNumber: 1, episodeNumber: 2);

        await isar.close();
        isar = await open();

        final optOut = (await MediaListLocalDataSource(
          isar,
        ).getOptOuts()).single;
        expect(optOut.tmdbId, 100);
        expect(optOut.seasonNumber, 1);
        expect(optOut.episodeNumber, 2);
      },
    );
  });
}
