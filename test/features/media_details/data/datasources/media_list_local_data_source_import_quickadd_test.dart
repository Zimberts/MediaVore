import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'dart:io';

import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

void main() {
  late Isar isar;
  late MediaListLocalDataSource local;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_datasource_import_quickadd';
    if (!Directory(tempPath).existsSync()) {
      Directory(tempPath).createSync(recursive: true);
    }
  });

  setUp(() async {
    isar = await Isar.open(
      [
        QuickAddItemModelSchema,
        MediaListItemSchema,
        UserListSchema,
        SeenItemModelSchema,
        LikedItemSchema,
        NotifiedItemModelSchema,
      ],
      directory: tempPath,
      name: 'test_qa_import_db_${DateTime.now().millisecondsSinceEpoch}',
    );
    local = MediaListLocalDataSource(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('importQuickAddItems', () {
    test('imports quickadd items in append mode', () async {
      final items = [
        QuickAddItemModel(
          tmdbId: 100,
          type: 'tv',
          seasonNumber: 1,
          episodeNumber: 5,
          insertedAt: DateTime.utc(2025, 1, 1),
          airDate: DateTime.utc(2025, 1, 8),
          title: 'Show A',
          posterPath: '/a.jpg',
        ),
        QuickAddItemModel(
          tmdbId: 200,
          type: 'tv',
          seasonNumber: 2,
          episodeNumber: 3,
          insertedAt: DateTime.utc(2025, 1, 2),
          airDate: DateTime.utc(2025, 1, 9),
          title: 'Show B',
          posterPath: '/b.jpg',
        ),
      ];

      await local.importQuickAddItems(items, mode: ImportMode.append);

      final saved = await local.getQuickAddItems();
      expect(saved.length, 2);
      // getQuickAddItems returns sorted by insertedAt desc, so 200 (newer) comes first
      expect(saved[0].tmdbId, 200);
      expect(saved[1].tmdbId, 100);
    });

    test('imports quickadd items in replace mode', () async {
      // Add initial item
      final existing = QuickAddItemModel(
        tmdbId: 999,
        type: 'tv',
        seasonNumber: 1,
        episodeNumber: 1,
        insertedAt: DateTime.utc(2024, 1, 1),
        title: 'Old Show',
      );
      await local.addQuickAddItem(existing);

      // Verify it exists
      var saved = await local.getQuickAddItems();
      expect(saved.length, 1);

      // Replace with new items
      final newItems = [
        QuickAddItemModel(
          tmdbId: 100,
          type: 'tv',
          seasonNumber: 1,
          episodeNumber: 5,
          insertedAt: DateTime.utc(2025, 1, 1),
          title: 'New Show A',
        ),
      ];

      await local.importQuickAddItems(newItems, mode: ImportMode.replace);

      saved = await local.getQuickAddItems();
      expect(saved.length, 1);
      expect(saved[0].tmdbId, 100);
      expect(saved[0].title, 'New Show A');
    });

    test('imports quickadd items in merge mode with deduplication', () async {
      // Add initial item
      final existing = QuickAddItemModel(
        tmdbId: 100,
        type: 'tv',
        seasonNumber: 1,
        episodeNumber: 5,
        insertedAt: DateTime.utc(2025, 1, 1),
        title: 'Show A',
      );
      await local.addQuickAddItem(existing);

      // Try to import duplicate + new
      final itemsToImport = [
        QuickAddItemModel(
          tmdbId: 100,
          type: 'tv',
          seasonNumber: 1,
          episodeNumber: 5,
          insertedAt: DateTime.utc(2025, 1, 1),
          title: 'Show A Duplicate',
        ),
        QuickAddItemModel(
          tmdbId: 200,
          type: 'tv',
          seasonNumber: 2,
          episodeNumber: 3,
          insertedAt: DateTime.utc(2025, 1, 2),
          title: 'Show B',
        ),
      ];

      await local.importQuickAddItems(itemsToImport, mode: ImportMode.merge);

      final saved = await local.getQuickAddItems();
      // Should have original + only the new one (duplicate skipped)
      expect(saved.length, 2);
      final tmdbIds = saved.map((e) => e.tmdbId).toList();
      expect(tmdbIds.contains(100), true);
      expect(tmdbIds.contains(200), true);
    });

    test('handles empty import list gracefully', () async {
      await local.importQuickAddItems([], mode: ImportMode.append);

      final saved = await local.getQuickAddItems();
      expect(saved.length, 0);
    });

    test('reports progress during import', () async {
      final progressReports = <(double, String)>[];

      final items = List.generate(
        3,
        (i) => QuickAddItemModel(
          tmdbId: 100 + i,
          type: 'tv',
          seasonNumber: 1,
          episodeNumber: 1,
          insertedAt: DateTime.now(),
          title: 'Show $i',
        ),
      );

      await local.importQuickAddItems(
        items,
        mode: ImportMode.append,
        onProgress: (progress, status) {
          progressReports.add((progress, status));
        },
      );

      // Verify progress was reported
      expect(progressReports.isNotEmpty, true);
      expect(progressReports.last.$1, greaterThan(0.0));
      expect(progressReports.last.$2.contains('quick add'), true);
    });

    test('preserves all fields during import', () async {
      final item = QuickAddItemModel(
        tmdbId: 100,
        type: 'tv',
        seasonNumber: 2,
        episodeNumber: 10,
        insertedAt: DateTime.utc(2025, 1, 15, 14, 30, 45),
        airDate: DateTime.utc(2025, 1, 22, 20, 0, 0),
        title: 'Breaking Bad',
        posterPath: '/poster.jpg',
      );

      await local.importQuickAddItems([item], mode: ImportMode.append);

      final saved = await local.getQuickAddItems();
      expect(saved.length, 1);
      final imported = saved[0];

      expect(imported.tmdbId, 100);
      expect(imported.type, 'tv');
      expect(imported.seasonNumber, 2);
      expect(imported.episodeNumber, 10);
      expect(imported.title, 'Breaking Bad');
      expect(imported.posterPath, '/poster.jpg');
      // Verify datetimes are preserved (within the same day, accounting for timezone)
      expect(imported.insertedAt.year, 2025);
      expect(imported.insertedAt.month, 1);
      expect(imported.insertedAt.day, 15);
      expect(imported.airDate?.year, 2025);
      expect(imported.airDate?.month, 1);
      expect(imported.airDate?.day, 22);
    });
  });
}
