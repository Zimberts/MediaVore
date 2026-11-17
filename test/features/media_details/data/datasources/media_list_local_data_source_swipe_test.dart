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
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';

void main() {
  late MediaListLocalDataSource dataSource;
  late Isar isar;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_swipe_decisions';
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
        QuickAddOptOutModelSchema,
        SwipeDecisionModelSchema,
      ],
      directory: tempPath,
      name: 'test_swipe_decisions_db',
    );
    dataSource = MediaListLocalDataSource(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test(
    'recordSwipeDecision persists decision and getDecidedTmdbIds returns it',
    () async {
      final decision = SwipeDecisionModel(
        tmdbId: 101,
        mediaType: 'movie',
        title: 'Inception',
        decision: 'added',
        decidedAt: DateTime.now(),
        targetList: 'watchlist',
      );

      await dataSource.recordSwipeDecision(decision);

      final decidedIds = await dataSource.getDecidedTmdbIds();
      expect(decidedIds, contains(101));

      final decisions = await dataSource.getSwipeDecisions();
      expect(decisions.length, 1);
      expect(decisions.first.title, 'Inception');
      expect(decisions.first.decision, 'added');
    },
  );

  test(
    'recordSwipeDecisions persists batch and undoLastSwipeDecision rolls back saga',
    () async {
      final now = DateTime.now();
      final d1 = SwipeDecisionModel(
        tmdbId: 201,
        mediaType: 'movie',
        title: 'Saga Part 1',
        decision: 'added',
        decidedAt: now,
        collectionId: 999,
        collectionName: 'Epic Saga',
        targetList: 'watchlist',
      );
      final d2 = SwipeDecisionModel(
        tmdbId: 202,
        mediaType: 'movie',
        title: 'Saga Part 2',
        decision: 'added',
        decidedAt: now,
        collectionId: 999,
        collectionName: 'Epic Saga',
        targetList: 'watchlist',
      );

      await dataSource.recordSwipeDecisions([d1, d2]);

      var decidedIds = await dataSource.getDecidedTmdbIds();
      expect(decidedIds, {201, 202});

      // Undo saga
      final undone = await dataSource.undoLastSwipeDecision();
      expect(undone, isNotNull);
      expect(undone!.collectionId, 999);

      decidedIds = await dataSource.getDecidedTmdbIds();
      expect(decidedIds.isEmpty, true);
    },
  );

  test('clearAllSwipeDecisions clears all stored decisions', () async {
    await dataSource.recordSwipeDecision(
      SwipeDecisionModel(
        tmdbId: 301,
        title: 'Movie 301',
        decision: 'discarded',
        decidedAt: DateTime.now(),
      ),
    );

    expect((await dataSource.getDecidedTmdbIds()).isNotEmpty, true);

    await dataSource.clearAllSwipeDecisions();
    expect((await dataSource.getDecidedTmdbIds()).isEmpty, true);
  });
}
