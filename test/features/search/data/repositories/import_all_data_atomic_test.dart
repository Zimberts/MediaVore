import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

import '../../../../helpers/mocks.dart';

SeenItemModel _seen(int tmdbId, String title) => SeenItemModel(
  tmdbId: tmdbId,
  type: 'movie',
  title: title,
  posterPath: null,
  seenDate: DateTime.utc(2025, 1, 1),
  runtime: 100,
  genres: const ['Drama'],
);

void main() {
  late Isar isar;
  late MediaListLocalDataSource local;
  late MediaRepositoryImpl repo;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_repo_import_atomic';
    if (!Directory(tempPath).existsSync()) {
      Directory(tempPath).createSync(recursive: true);
    }
  });

  setUp(() async {
    isar = await Isar.open(
      [
        MediaListItemSchema,
        UserListSchema,
        SeenItemModelSchema,
        LikedItemSchema,
        NotifiedItemModelSchema,
        QuickAddItemModelSchema,
      ],
      directory: tempPath,
      name: 'test_import_atomic_${DateTime.now().microsecondsSinceEpoch}',
    );
    local = MediaListLocalDataSource(isar);
    repo = MediaRepositoryImpl(
      remoteDataSource: MediaRemoteDataSource(
        dio: Dio(),
        credentials: FakeTmdbCredentialStore('mock_token'),
        locale: FakeLocaleService(),
      ),
      localDataSource: local,
      cache: MediaCache(isar),
      autoInit: false,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('importAllData atomicity', () {
    test(
      'should leave the database unchanged when a later stage fails in replace mode',
      () async {
        await local.markAsSeen(_seen(1, 'Old seen'));
        await local.toggleLike(tmdbId: 2, type: 'movie', title: 'Old like');
        await local.addToList(
          id: 3,
          type: 'movie',
          listName: 'watchlist',
          title: 'Old list item',
        );

        // Duplicate (tmdbId, type) violates LikedItem's unique index, so the
        // likes stage throws after the seen stage has been written.
        final zip = ExportEnvelope(
          version: 1,
          exportedAt: DateTime.utc(2025, 1, 1),
          seen: [_seen(10, 'New seen')],
          likes: [
            LikedItem(tmdbId: 20, type: 'movie', title: 'Dup'),
            LikedItem(tmdbId: 20, type: 'movie', title: 'Dup'),
          ],
          lists: {
            'watchlist': [
              MediaListItem(
                id: 30,
                type: 'movie',
                title: 'New list item',
                listName: 'watchlist',
                position: 0,
              ),
            ],
          },
        ).toZipBytes();

        await expectLater(
          repo.importAllData(zip, mode: ImportMode.replace),
          throwsA(anything),
        );

        final seen = await local.getAllSeenItems();
        expect(seen.map((s) => s.tmdbId), [1]);
        final likes = await local.getLikedItems();
        expect(likes.map((l) => l.tmdbId), [2]);
        final list = await local.getListItems('watchlist');
        expect(list.map((i) => i.id), [3]);
      },
    );

    test('should replace every collection when the import succeeds', () async {
      await local.markAsSeen(_seen(1, 'Old seen'));
      await local.toggleLike(tmdbId: 2, type: 'movie', title: 'Old like');

      final zip = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025, 1, 1),
        seen: [_seen(10, 'New seen')],
        likes: [LikedItem(tmdbId: 20, type: 'movie', title: 'New like')],
      ).toZipBytes();

      await repo.importAllData(zip, mode: ImportMode.replace);

      final seen = await local.getAllSeenItems();
      expect(seen.map((s) => s.tmdbId), [10]);
      final likes = await local.getLikedItems();
      expect(likes.map((l) => l.tmdbId), [20]);
    });
  });
}
