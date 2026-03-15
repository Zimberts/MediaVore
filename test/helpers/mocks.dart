import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/cache/media_cache.dart';

class MockDio extends Mock implements Dio {}

class MockMediaRepository extends Mock implements MediaRepository {
  @override
  Future<List<QuickAddItem>> getQuickAddItems() {
    try {
      return super.noSuchMethod(Invocation.method(#getQuickAddItems, []))
          as Future<List<QuickAddItem>>;
    } catch (_) {
      return Future.value(<QuickAddItem>[]);
    }
  }

  @override
  Future<void> removeQuickAddItemById(int isarId) {
    try {
      return super.noSuchMethod(
            Invocation.method(#removeQuickAddItemById, [isarId]),
          )
          as Future<void>;
    } catch (_) {
      return Future.value();
    }
  }

  @override
  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) {
    try {
      return super.noSuchMethod(
            Invocation.method(
              #optOutSeries,
              [tmdbId],
              {#seasonNumber: seasonNumber, #episodeNumber: episodeNumber},
            ),
          )
          as Future<void>;
    } catch (_) {
      return Future.value();
    }
  }

  @override
  Future<void> clearOptOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) {
    try {
      return super.noSuchMethod(
            Invocation.method(
              #clearOptOutSeries,
              [tmdbId],
              {#seasonNumber: seasonNumber, #episodeNumber: episodeNumber},
            ),
          )
          as Future<void>;
    } catch (_) {
      return Future.value();
    }
  }

  @override
  Future<void> populateQuickAddFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  }) {
    try {
      return super.noSuchMethod(
            Invocation.method(#populateQuickAddFromSeenHistory, [], {
              #tmdbId: tmdbId,
              #tailSeason: tailSeason,
              #tailEpisode: tailEpisode,
            }),
          )
          as Future<void>;
    } catch (_) {
      return Future.value();
    }
  }

  @override
  Future<void> updateSeenEntry(SeenItem item) {
    try {
      return super.noSuchMethod(Invocation.method(#updateSeenEntry, [item]))
          as Future<void>;
    } catch (_) {
      return Future.value();
    }
  }
}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockMediaRemoteDataSource extends Mock implements MediaRemoteDataSource {}

class MockMediaListLocalDataSource extends Mock
    implements MediaListLocalDataSource {}

class MockIsar extends Mock implements Isar {}

class MockMediaCache extends Mock implements MediaCache {}

class MockAchievementRepository extends Mock implements AchievementRepository {}

class MockAchievementProvider extends Mock implements AchievementProvider {}

class FakeSeenItem extends Fake implements SeenItem {}

class FakeMediaItem extends Fake implements MediaItem {}

class FakeQuickAddItem extends Fake implements QuickAddItem {}
