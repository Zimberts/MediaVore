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
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

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
    tempPath = '${Directory.current.path}/test/tmp_repo_import_all_quickadd';
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
      name: 'test_repo_import_all_qa_db_${DateTime.now().millisecondsSinceEpoch}',
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

  test('importAllData includes and imports quickadd items', () async {
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
      quickAdd: [
        QuickAddItemModel(
          tmdbId: 400,
          type: 'tv',
          seasonNumber: 2,
          episodeNumber: 5,
          insertedAt: DateTime.utc(2025, 1, 15),
          airDate: DateTime.utc(2025, 2, 1),
          title: 'Show Next Episode',
          posterPath: '/show.jpg',
        ),
      ],
      lists: {
        'Imported': [
          MediaListItem(
            id: 500,
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

    // Verify quickadd was imported
    final quickAdd = await local.getQuickAddItems();
    expect(quickAdd.length, 1);
    expect(quickAdd[0].tmdbId, 400);
    expect(quickAdd[0].seasonNumber, 2);
    expect(quickAdd[0].episodeNumber, 5);
    expect(quickAdd[0].title, 'Show Next Episode');

    // Verify other data was also imported
    final seen = await local.getAllSeenItems();
    expect(seen.length, 1);
    expect(seen[0].tmdbId, 100);

    final likes = await local.getLikedItems();
    expect(likes.length, 1);
    expect(likes[0].tmdbId, 200);

    final nots = await local.getNotifiedItems();
    expect(nots.length, 1);
    expect(nots[0].tmdbId, 300);

    final listItems = await local.getListItems('Imported');
    expect(listItems.length, 1);
    expect(listItems[0].id, 500);
  });

  test('importAllData with empty quickadd handles gracefully', () async {
    final envelopeObj = ExportEnvelope(
      version: 1,
      exportedAt: DateTime.now(),
      seen: [],
      likes: [],
      notifications: [],
      quickAdd: [], // Empty
      lists: {},
    );

    final zipBytes = envelopeObj.toZipBytes();

    await repo.importAllData(zipBytes, mode: ImportMode.merge);

    final quickAdd = await local.getQuickAddItems();
    expect(quickAdd.length, 0);
  });

  test('importAllData in replace mode clears old quickadd', () async {
    // Add initial quickadd
    final oldItem = QuickAddItemModel(
      tmdbId: 999,
      type: 'tv',
      seasonNumber: 1,
      episodeNumber: 1,
      insertedAt: DateTime.utc(2024, 1, 1),
      title: 'Old Show',
    );
    await local.addQuickAddItem(oldItem);

    // Verify exists
    var saved = await local.getQuickAddItems();
    expect(saved.length, 1);

    // Import with replace mode
    final envelopeObj = ExportEnvelope(
      version: 1,
      exportedAt: DateTime.now(),
      quickAdd: [
        QuickAddItemModel(
          tmdbId: 100,
          type: 'tv',
          seasonNumber: 2,
          episodeNumber: 5,
          insertedAt: DateTime.utc(2025, 1, 15),
          title: 'New Show',
        ),
      ],
    );

    final zipBytes = envelopeObj.toZipBytes();
    await repo.importAllData(zipBytes, mode: ImportMode.replace);

    saved = await local.getQuickAddItems();
    expect(saved.length, 1);
    expect(saved[0].tmdbId, 100);
  });

  test('importAllData in merge mode deduplicates quickadd', () async {
    // Add initial quickadd
    final existing = QuickAddItemModel(
      tmdbId: 100,
      type: 'tv',
      seasonNumber: 2,
      episodeNumber: 5,
      insertedAt: DateTime.utc(2025, 1, 15),
      title: 'Show A',
    );
    await local.addQuickAddItem(existing);

    // Import with duplicate + new
    final envelopeObj = ExportEnvelope(
      version: 1,
      exportedAt: DateTime.now(),
      quickAdd: [
        QuickAddItemModel(
          tmdbId: 100,
          type: 'tv',
          seasonNumber: 2,
          episodeNumber: 5,
          insertedAt: DateTime.utc(2025, 1, 15),
          title: 'Show A Dup',
        ),
        QuickAddItemModel(
          tmdbId: 200,
          type: 'tv',
          seasonNumber: 1,
          episodeNumber: 1,
          insertedAt: DateTime.utc(2025, 1, 10),
          title: 'Show B',
        ),
      ],
    );

    final zipBytes = envelopeObj.toZipBytes();
    await repo.importAllData(zipBytes, mode: ImportMode.merge);

    final saved = await local.getQuickAddItems();
    expect(saved.length, 2); // Only the original + new one
    final tmdbIds = saved.map((e) => e.tmdbId).toSet();
    expect(tmdbIds.contains(100), true);
    expect(tmdbIds.contains(200), true);
  });

  test('export/import round-trip preserves quickadd', () async {
    // Add quickadd to local db
    final original = QuickAddItemModel(
      tmdbId: 555,
      type: 'tv',
      seasonNumber: 3,
      episodeNumber: 7,
      insertedAt: DateTime.utc(2025, 2, 1),
      airDate: DateTime.utc(2025, 2, 8),
      title: 'The Crown',
      posterPath: '/crown.jpg',
    );
    await local.addQuickAddItem(original);

    // Export
    final exported = await repo.exportAllData();

    // Clear db
    await local.clearQuickAddItems();
    var cleared = await local.getQuickAddItems();
    expect(cleared.length, 0);

    // Import
    await repo.importAllData(exported, mode: ImportMode.append);

    // Verify
    final imported = await local.getQuickAddItems();
    expect(imported.length, 1);
    expect(imported[0].tmdbId, 555);
    expect(imported[0].seasonNumber, 3);
    expect(imported[0].title, 'The Crown');
  });
}
