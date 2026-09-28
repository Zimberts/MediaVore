# Test fixtures

## `isar_v3_default.isar.gz`

> **IMPORTANT — one-of-a-kind artifact. Do not regenerate, reformat, rename, or
> replace it casually.**

A database written by the **legacy, abandoned `isar` 3.1.0+1 package**, captured
before this project migrated to `isar_community`. It exists so
`test/core/database/isar_v3_format_compat_test.dart` can prove that a database
created by the old package still opens, reads, and writes under the new one —
i.e. that existing users keep their data and no data migration is required.

| | |
| --- | --- |
| Written by | `isar` **3.1.0+1** (do not substitute the current package) |
| File name inside the archive | `default.isar` (matches the app's real database) |
| Uncompressed size | 1,048,576 bytes (mostly MDBX preallocated space) |
| Compressed size | 3,343 bytes |
| SHA-256 (committed `.gz`) | `9F5AC4B382A2B652ACD0AF9F33C0D68783828C3030DA6597503FAC0CBD097096` |

### Why it cannot be regenerated from the current codebase

Any database written *today* is written by `isar_community`. Feeding that back
into the compatibility test would be circular: it would prove only that the new
package agrees with itself, never that it can read a legacy file. The blob is the
only surviving sample of the old format, so it is a fixture, not a build product.

### When replacement is legitimate

Only when **all** of these hold:

1. A deliberate, reviewed persistence change requires it — for example migrating
   off Isar entirely, or moving past the v3 on-disk format.
2. The replacement is generated with the **legacy `isar` 3.1.0+1 package**, never
   with the current one.
3. `test/core/database/isar_v3_format_compat_test.dart` (its assertions, doc
   comment, and the SHA-256 recorded above) is updated in the same change.

A failing assertion in that test is otherwise a **real regression — silent data
loss for existing users**. Fix the code, not the fixture.

### Strict regeneration procedure

Do this in a throwaway checkout so the working tree is never destabilised.

1. Get a checkout that still pins the legacy toolchain — the cleanest source is
   the commit *before* the `isar_community` migration (it already has
   `isar 3.1.0+1` plus a compatible `analyzer <7` codegen stack in
   `pubspec.lock`):

   ```bash
   git worktree add ../mediavore-legacy <commit-before-isar_community-migration>
   cd ../mediavore-legacy
   flutter pub get
   ```

   Do not mix the legacy `isar_generator` with the modern codegen stack in the
   main checkout: `isar_generator` 3.1.0+1 requires `analyzer <7`, which conflicts
   with `isar_community_generator`'s `analyzer >=8`.

2. Add this scratch generator as `test/tmp_generate_v3_fixture_test.dart`:

   ```dart
   import 'dart:io';

   import 'package:flutter_test/flutter_test.dart';
   import 'package:isar/isar.dart';
   import 'package:mediavore/core/cache/cached_media.dart';
   import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
   import 'package:mediavore/features/media_details/data/models/liked_item.dart';
   import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
   import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
   import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
   import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
   import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
   import 'package:mediavore/features/media_details/data/models/user_list.dart';

   void main() {
     test('generate legacy v3 isar fixture', () async {
       await Isar.initializeIsarCore(download: true);

       final dir = '${Directory.current.path}/test/tmp_isar_v3_fixture';
       if (!Directory(dir).existsSync()) {
         Directory(dir).createSync(recursive: true);
       }

       final isar = await Isar.open(
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
         directory: dir,
       );

       await isar.writeTxn(() async {
         await isar.userLists.put(UserList(name: 'watchlist'));
         await isar.userLists.put(UserList(name: 'favorites'));
         await isar.mediaListItems.putAll([
           MediaListItem(
             id: 550,
             type: 'movie',
             title: 'Fight Club',
             listName: 'watchlist',
             position: 0,
           ),
           MediaListItem(
             id: 1399,
             type: 'tv',
             title: 'Game of Thrones',
             listName: 'favorites',
             position: 1,
           ),
         ]);
         await isar.seenItemModels.putAll([
           SeenItemModel(
             tmdbId: 550,
             type: 'movie',
             title: 'Fight Club',
             seenDate: DateTime(2023, 10, 1),
             runtime: 139,
             genres: const ['Drama', 'Thriller'],
           ),
           SeenItemModel(
             tmdbId: 1399,
             type: 'tv',
             title: 'Game of Thrones',
             seenDate: DateTime(2023, 10, 2),
             seasonNumber: 1,
             episodeNumber: 1,
           ),
         ]);
         await isar.likedItems.put(
           LikedItem(tmdbId: 550, type: 'movie', title: 'Fight Club'),
         );
         await isar.cachedMedias.put(
           CachedMedia(
             tmdbId: 550,
             type: 'movie',
             mediaDetailsJson: '{"id":550,"title":"Fight Club"}',
             updatedAt: DateTime(2023, 10, 4),
           ),
         );
         await isar.cachedSeasons.put(
           CachedSeason(
             tvId: 1399,
             seasonNumber: 1,
             json: '{"season_number":1}',
             updatedAt: DateTime(2023, 10, 5),
           ),
         );
         await isar.achievementModels.put(
           AchievementModel(
             achievementId: 'first_seen',
             unlockedAt: DateTime(2023, 10, 6),
           ),
         );
       });

       await isar.close();
     });
   }
   ```

3. Generate it:

   ```bash
   flutter test test/tmp_generate_v3_fixture_test.dart
   ```

4. Gzip it (`.gitignore` ignores `*.isar`, so it must be stored compressed) and
   copy it into the main checkout. From the **main** checkout, with
   `$LEGACY` pointing at the worktree:

   ```powershell
   $src = [System.IO.File]::ReadAllBytes("$LEGACY/test/tmp_isar_v3_fixture/default.isar")
   $ms = New-Object System.IO.MemoryStream
   $gz = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionLevel]::Optimal)
   $gz.Write($src, 0, $src.Length); $gz.Close()
   [System.IO.File]::WriteAllBytes("test/fixtures/isar_v3_default.isar.gz", $ms.ToArray())
   ```

5. Clean up the worktree:

   ```bash
   git worktree remove ../mediavore-legacy --force
   ```

6. Verify and re-record:

   ```bash
   flutter test test/core/database/isar_v3_format_compat_test.dart
   Get-FileHash test/fixtures/isar_v3_default.isar.gz -Algorithm SHA256   # update the table above
   ```

### Data the fixture must contain

The assertions in `isar_v3_format_compat_test.dart` depend on exactly this seed
data. Keep them in sync if you ever replace the blob:

| Collection | Rows | Notable values asserted |
| --- | --- | --- |
| `UserList` | 2 | `watchlist`, `favorites` (tests the unique `name` index) |
| `MediaListItem` | 2 | Fight Club 550 / GoT 1399 (tests the composite `id_type_listName` index) |
| `SeenItemModel` | 2 | `runtime`, `genres` list, `seenDate` preserved |
| `LikedItem` | 1 | — |
| `CachedMedia` | 1 | JSON payload preserved |
| `CachedSeason` | 1 | — |
| `AchievementModel` | 1 | `first_seen`, `unlockedAt` preserved |
