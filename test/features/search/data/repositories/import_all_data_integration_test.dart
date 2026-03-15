import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:mocktail/mocktail.dart';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

import 'package:mediavore/core/utils/export_import_serializer.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late Isar isar;
  late MediaListLocalDataSource local;
  late MediaCache cache;
  late MediaRepositoryImpl repo;
  late String tempPath;
  late MockSharedPreferences mockPrefs;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_repo_import_all';
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
      ],
      directory: tempPath,
      name: 'test_repo_import_all_db',
    );
    local = MediaListLocalDataSource(isar);
    cache = MediaCache(isar);
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getString('tmdbApiKey')).thenReturn('mock_token');
    final remote = MediaRemoteDataSource(dio: Dio(), prefs: mockPrefs);
    repo = MediaRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      cache: cache,
      autoInit: false,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('importAllData inserts seen, likes, notifications and lists', () async {
    final envelopeObj = ExportEnvelope(
      version: 1,
      exportedAt: DateTime.now(),
      seen: [
        SeenItemModel(
          tmdbId: 100,
          type: 'movie',
          title: 'Imported Movie',
          posterPath: null,
          seenDate: DateTime.utc(2025, 1, 1),
          runtime: 110,
          genres: ['Drama'],
        ),
      ],
      likes: [LikedItem(tmdbId: 200, type: 'movie', title: 'Liked Movie')],
      notifications: [
        NotifiedItemModel(
          tmdbId: 300,
          type: 'tv',
          title: 'Notify Show',
          posterPath: null,
          releaseDate: DateTime.utc(2026, 1, 1),
          seasonNumber: 1,
          episodeNumber: 1,
          autoNotify: true,
        ),
      ],
      lists: {
        'Imported': [
          MediaListItem(
            id: 400,
            type: 'movie',
            title: 'ListItem',
            listName: 'Imported',
            position: 0,
          ),
        ],
      },
    );

    final zipBytes = envelopeObj.toZipBytes();

    await repo.importAllData(zipBytes, mode: ImportMode.merge);

    final seen = await local.getAllSeenItems();
    final likes = await local.getLikedItems();
    final nots = await local.getNotifiedItems();
    final listItems = await local.getListItems('Imported');

    expect(seen.length, 1);
    expect(seen.first.tmdbId, 100);

    expect(likes.length, 1);
    expect(likes.first.tmdbId, 200);

    expect(nots.length, 1);
    expect(nots.first.tmdbId, 300);

    expect(listItems.length, 1);
    expect(listItems.first.id, 400);
  });
}
