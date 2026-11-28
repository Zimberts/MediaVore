import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/media_details/data/datasources/manual_media_local_data_source.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/manual_media_model.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/services/import_export_service.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemote extends Mock implements MediaRemoteDataSource {}

void main() {
  group('ExportEnvelope manualMedia', () {
    test(
      'should round-trip manual media and omit local poster paths',
      () async {
        final now = DateTime.utc(2026, 11, 28, 12);
        final envelope = ExportEnvelope(
          version: 1,
          exportedAt: now,
          manualMedia: [
            ManualMediaModel(
              localId: -1,
              kind: ManualMediaKind.video,
              title: 'Local Video',
              posterPath: '/data/user/0/app/manual_posters/p.jpg',
              runtime: 12,
              genres: ['Documentary'],
              originCountries: ['FR'],
              sourceUrl: 'https://example.com/v',
              createdAt: now,
              updatedAt: now,
            ),
            ManualMediaModel(
              localId: -2,
              kind: ManualMediaKind.tv,
              title: 'Web Series',
              posterPath: 'https://example.com/poster.jpg',
              seasons: [4, 6],
              createdAt: now,
              updatedAt: now,
            ),
          ],
          seen: [
            SeenItemModel(
              tmdbId: -1,
              type: 'movie',
              title: 'Local Video',
              seenDate: now,
              runtime: 12,
            ),
          ],
          likes: [LikedItem(tmdbId: -1, type: 'movie', title: 'Local Video')],
          lists: {
            'watchlist': [
              MediaListItem(
                id: -2,
                type: 'tv',
                title: 'Web Series',
                listName: 'watchlist',
              ),
            ],
          },
        );

        final bytes = envelope.toZipBytes();
        final decoded = ExportEnvelope.fromZipBytes(bytes);

        expect(decoded.warnings, isEmpty);
        expect(decoded.manualMedia.length, 2);
        expect(decoded.manualMedia[0].localId, -1);
        expect(decoded.manualMedia[0].posterPath, isNull);
        expect(
          decoded.manualMedia[1].posterPath,
          'https://example.com/poster.jpg',
        );
        expect(decoded.manualMedia[1].seasons, [4, 6]);
        expect(decoded.seen.single.tmdbId, -1);
        expect(decoded.likes.single.tmdbId, -1);
        expect(decoded.lists['watchlist']?.single.id, -2);
      },
    );

    test(
      'should import v1.4.x archive without manualmedia.csv without errors',
      () {
        final legacy = ExportEnvelope(
          version: 1,
          exportedAt: DateTime.utc(2025, 1, 1),
          seen: [
            SeenItemModel(
              tmdbId: 550,
              type: 'movie',
              title: 'Fight Club',
              seenDate: DateTime.utc(2025, 1, 1),
            ),
          ],
        );
        final decoded = ExportEnvelope.fromZipBytes(legacy.toZipBytes());
        expect(decoded.warnings, isEmpty);
        expect(decoded.manualMedia, isEmpty);
        expect(decoded.seen.single.tmdbId, 550);
      },
    );
  });

  group('ImportExportService manualMedia ID reassignment', () {
    const dirPath = 'test/tmp_export_manual';
    late Isar isar;
    late ManualMediaLocalDataSource manualDs;
    late MediaListLocalDataSource localDs;
    late ImportExportService service;
    late _MockRemote remote;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
    });

    setUp(() async {
      final dir = Directory(dirPath);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      isar = await Isar.open([
        UserListSchema,
        MediaListItemSchema,
        SeenItemModelSchema,
        LikedItemSchema,
        NotifiedItemModelSchema,
        QuickAddItemModelSchema,
        QuickAddOptOutModelSchema,
        SwipeDecisionModelSchema,
        CachedMediaSchema,
        CachedActorProfileSchema,
        CachedSeasonSchema,
        AchievementModelSchema,
        ManualMediaModelSchema,
      ], directory: dirPath);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      manualDs = ManualMediaLocalDataSource(isar, prefs);
      localDs = MediaListLocalDataSource(isar);
      remote = _MockRemote();
      final cache = MediaCache(isar);
      final details = MediaDetailsService(
        remoteDataSource: remote,
        cache: cache,
        manualMediaDataSource: manualDs,
      );
      service = ImportExportService(
        localDataSource: localDs,
        details: details,
        manualMediaDataSource: manualDs,
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      final dir = Directory(dirPath);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test(
      'should reassign colliding negative IDs on append import and update references',
      () async {
        final existing = await manualDs.createManualMedia(
          kind: ManualMediaKind.movie,
          title: 'Existing Local',
        );
        expect(existing.localId, -1);

        final now = DateTime.utc(2026, 11, 28);
        final archiveBytes = ExportEnvelope(
          version: 1,
          exportedAt: now,
          manualMedia: [
            ManualMediaModel(
              localId: -1,
              kind: ManualMediaKind.video,
              title: 'Imported Video',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          seen: [
            SeenItemModel(
              tmdbId: -1,
              type: 'movie',
              title: 'Imported Video',
              seenDate: now,
            ),
          ],
          likes: [
            LikedItem(tmdbId: -1, type: 'movie', title: 'Imported Video'),
          ],
          lists: {
            'watchlist': [
              MediaListItem(
                id: -1,
                type: 'movie',
                title: 'Imported Video',
                listName: 'watchlist',
              ),
            ],
          },
        ).toZipBytes();

        await service.importAllData(archiveBytes, mode: ImportMode.append);

        final allManual = await manualDs.getAll();
        expect(allManual.length, 2);
        final imported = allManual.firstWhere(
          (m) => m.title == 'Imported Video',
        );
        expect(imported.localId, -2);

        final seen = await localDs.getAllSeenItems();
        expect(seen.single.tmdbId, -2);

        final likes = await localDs.getLikedItems();
        expect(likes.single.tmdbId, -2);

        final watchlist = await localDs.getListItems('watchlist');
        expect(watchlist.single.id, -2);

        verifyZeroInteractions(remote);
      },
    );
  });
}
