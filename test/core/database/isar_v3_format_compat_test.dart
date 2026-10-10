import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';

/// Guards the `isar` v3 -> `isar_community` v3 migration: the on-disk database
/// format must stay compatible so existing users keep their data.
///
/// =============================================================================
/// `test/fixtures/isar_v3_default.isar.gz` IS AN IMPORTANT, ONE-OF-A-KIND
/// ARTIFACT. DO NOT REGENERATE, REFORMAT, RENAME, OR REPLACE IT CASUALLY.
/// =============================================================================
///
/// It is a database written by the **legacy, abandoned `isar` 3.1.0+1 package**
/// (gzipped because `.gitignore` ignores `*.isar`). It is the only surviving
/// record of the pre-migration on-disk format, and therefore the only thing that
/// can prove an existing user's data still opens after a persistence change.
///
/// Nothing in the current codebase can recreate it: any database written today is
/// written by `isar_community`, which would make this test circular and
/// worthless. Regenerating it therefore requires temporarily reinstalling the
/// legacy packages — see `test/fixtures/README.md` for the exact, strict steps.
///
/// Replace it ONLY when all of the following hold:
///   1. A deliberate, reviewed persistence change requires it (e.g. migrating off
///      Isar entirely, or moving past the v3 on-disk format).
///   2. The replacement is generated with the **legacy** package, never with the
///      current one.
///   3. This file's assertions and `test/fixtures/README.md` (including its
///      recorded SHA-256) are updated in the same change.
///
/// Otherwise: treat a failure here as a REAL REGRESSION — silent data loss for
/// existing users — not as a stale fixture. Fix the code, not the fixture.
void main() {
  const runtimeDir = 'test/tmp_isar_v3_compat';
  const fixturePath = 'test/fixtures/isar_v3_default.isar.gz';

  late Isar isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);

    final dir = Directory(runtimeDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);

    // Guard: this fixture is a critical, non-reproducible artifact — a raw
    // FileSystemException would be a confusing way to discover it is missing.
    final fixture = File(fixturePath);
    if (!fixture.existsSync()) {
      fail(
        'Missing required test fixture: $fixturePath\n'
        'This file protects existing users from on-disk data loss and CANNOT be\n'
        'regenerated from the current codebase (it must be a database written by\n'
        'the legacy `isar` 3.1.0+1 package).\n'
        'Restore it from git (git checkout -- $fixturePath) instead of deleting\n'
        'or rewriting it. See test/fixtures/README.md.',
      );
    }

    // Restore the legacy DB under its original name so `Isar.open` finds it.
    final bytes = gzip.decode(fixture.readAsBytesSync());
    File('$runtimeDir/default.isar').writeAsBytesSync(bytes);

    isar = await Isar.open(
      [
        UserListSchema,
        MediaListItemSchema,
        SeenItemModelSchema,
        LikedItemSchema,
        NotifiedItemModelSchema,
        QuickAddItemModelSchema,
        QuickAddOptOutModelSchema,
        CachedMediaSchema,
        CachedActorProfileSchema,
        CachedSeasonSchema,
        AchievementModelSchema,
      ],
      directory: runtimeDir,
    );
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
    final dir = Directory(runtimeDir);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  group('isar v3 on-disk format compatibility', () {
    test('should open a database written by legacy isar 3.1.0+1', () {
      expect(isar.isOpen, isTrue);
    });

    test('should read all collections written by legacy isar', () async {
      expect(await isar.userLists.count(), 2);
      expect(await isar.mediaListItems.count(), 2);
      expect(await isar.seenItemModels.count(), 2);
      expect(await isar.likedItems.count(), 1);
      expect(await isar.cachedMedias.count(), 1);
      expect(await isar.cachedSeasons.count(), 1);
      expect(await isar.achievementModels.count(), 1);
    });

    test('should preserve field values and indexes from legacy isar', () async {
      final watchlist = await isar.userLists.getByName('watchlist');
      expect(watchlist, isNotNull);

      final seen = await isar.seenItemModels.filter().tmdbIdEqualTo(550).findFirst();
      expect(seen, isNotNull);
      expect(seen!.title, 'Fight Club');
      expect(seen.type, 'movie');
      expect(seen.runtime, 139);
      expect(seen.genres, ['Drama', 'Thriller']);
      expect(seen.seenDate, DateTime(2023, 10, 1));

      final composite = await isar.mediaListItems
          .getByIdTypeListName(550, 'movie', 'watchlist');
      expect(composite, isNotNull);
      expect(composite!.title, 'Fight Club');

      final achievement = await isar.achievementModels
          .getByAchievementId('first_seen');
      expect(achievement, isNotNull);
      expect(achievement!.unlockedAt, DateTime(2023, 10, 6));
    });

    test('should write to a database written by legacy isar', () async {
      await isar.writeTxn(() async {
        await isar.userLists.put(UserList(name: 'migrated'));
        await isar.seenItemModels.put(
          SeenItemModel(
            tmdbId: 27205,
            type: 'movie',
            title: 'Inception',
            seenDate: DateTime(2024, 1, 1),
          ),
        );
      });

      expect(await isar.userLists.getByName('migrated'), isNotNull);
      expect(await isar.seenItemModels.count(), 3);

      final written = await isar.seenItemModels.filter().tmdbIdEqualTo(27205).findFirst();
      expect(written, isNotNull);
      expect(written!.title, 'Inception');
    });
  });
}
