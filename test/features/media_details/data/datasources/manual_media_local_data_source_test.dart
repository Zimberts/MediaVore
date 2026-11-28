import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/datasources/manual_media_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/manual_media_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const dirPath = 'test/tmp_manual_media_ds';
  late Isar isar;
  late ManualMediaLocalDataSource dataSource;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    final dir = Directory(dirPath);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    isar = await Isar.open([ManualMediaModelSchema], directory: dirPath);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = ManualMediaLocalDataSource(isar, prefs);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    final dir = Directory(dirPath);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('ManualMediaLocalDataSource', () {
    test('should allocate decrementing negative IDs without reuse', () async {
      final first = await dataSource.createManualMedia(
        kind: ManualMediaKind.movie,
        title: 'Short Film',
        runtime: 18,
      );
      final second = await dataSource.createManualMedia(
        kind: ManualMediaKind.video,
        title: 'YouTube Essay',
        sourceUrl: 'https://example.com/v/1',
      );
      expect(first.localId, -1);
      expect(second.localId, -2);

      await dataSource.deleteByLocalId(second.localId);
      final third = await dataSource.createManualMedia(
        kind: ManualMediaKind.tv,
        title: 'Web Series',
        seasons: [5, 8],
      );
      expect(third.localId, -3);
    });

    test('should update and map ManualMedia to MediaItem', () async {
      final created = await dataSource.createManualMedia(
        kind: ManualMediaKind.videoSeries,
        title: 'Lecture Series',
        seasons: [4, 6],
        runtime: 25,
        genres: ['Documentary'],
        originCountries: ['FR'],
      );

      final updated = await dataSource.updateManualMedia(
        created.copyWith(title: 'Lecture Series Updated'),
      );
      expect(updated.title, 'Lecture Series Updated');

      final fetched = await dataSource.getByLocalId(created.localId);
      expect(fetched, isNotNull);
      final item = fetched!.toMediaItem();
      expect(item.id, created.localId);
      expect(item.isManual, isTrue);
      expect(item.canBeNotified, isFalse);
      expect(item.mediaType, MediaType.tv);
      expect(item.numberOfSeasons, 2);
      expect(item.numberOfEpisodes, 10);
      expect(item.seasons?.length, 2);
      expect(item.seasons?[1].episodeCount, 6);
    });
  });
}
