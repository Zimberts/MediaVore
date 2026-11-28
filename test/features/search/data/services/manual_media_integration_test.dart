import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/achievements/data/datasources/achievement_media_source.dart';
import 'package:mediavore/features/media_details/data/datasources/manual_media_local_data_source.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements MediaRemoteDataSource {}

class _MockCache extends Mock implements MediaCache {}

class _MockLocal extends Mock implements MediaListLocalDataSource {}

class _MockManualDs extends Mock implements ManualMediaLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late _MockLocal local;
  late _MockManualDs manualDs;

  final manualSeries = ManualMedia(
    localId: -1,
    kind: ManualMediaKind.tv,
    title: 'Web Series',
    releaseDate: '2024-05-01',
    runtime: 20,
    seasons: [3, 5],
    originCountries: const ['FR'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    local = _MockLocal();
    manualDs = _MockManualDs();
  });

  group('Manual media service integration', () {
    test(
      'MediaDetailsService should resolve manual media without TMDB calls',
      () async {
        when(
          () => manualDs.getByLocalId(-1),
        ).thenAnswer((_) async => manualSeries);

        final service = MediaDetailsService(
          remoteDataSource: remote,
          cache: cache,
          manualMediaDataSource: manualDs,
        );

        final details = await service.getMediaDetails(-1, type: MediaType.tv);
        expect(details.item.id, -1);
        expect(details.item.title, 'Web Series');
        expect(details.cast, isEmpty);

        final season2 = await service.getSeasonDetails(-1, 2);
        expect((season2['episodes'] as List).length, 5);
        verifyZeroInteractions(remote);
      },
    );

    test(
      'NotificationRefreshService should ignore manual media without TMDB calls',
      () async {
        final details = MediaDetailsService(
          remoteDataSource: remote,
          cache: cache,
          manualMediaDataSource: manualDs,
        );
        final scanner = NextEpisodeScanner(details);
        final quickAdd = QuickAddService(
          remoteDataSource: remote,
          localDataSource: local,
          cache: cache,
          details: details,
          scanner: scanner,
        );
        final notifications = NotificationRefreshService(
          remoteDataSource: remote,
          localDataSource: local,
          cache: cache,
          details: details,
          scanner: scanner,
          quickAdd: quickAdd,
        );

        await notifications.toggleNotification(manualSeries.toMediaItem());
        await notifications.refreshNotificationForSeries(-1, MediaType.tv);
        await notifications.refreshReturningSeries(-1);
        await notifications.refreshNotificationDateByTmdbId(-1, MediaType.tv);

        verifyZeroInteractions(remote);
        verifyZeroInteractions(local);
      },
    );

    test(
      'CachedAchievementMediaSource should resolve manual shows and titles safely',
      () async {
        when(
          () => manualDs.getByLocalId(-1),
        ).thenAnswer((_) async => manualSeries);

        final source = CachedAchievementMediaSource(cache, manualDs);
        final shows = await source.shows({-1});
        expect(shows[-1]?.episodeCounts, {1: 3, 2: 5});

        final titles = await source.titles({(-1, 'tv')});
        expect(titles[(-1, 'tv')]?.originCountries, ['FR']);
        expect(titles[(-1, 'tv')]?.voteAverage, isNull);

        expect(await source.sagas({-1}), isEmpty);
        expect(await source.episodeAirDates(-1, 1), isNull);
        verifyZeroInteractions(cache);
      },
    );
  });
}
