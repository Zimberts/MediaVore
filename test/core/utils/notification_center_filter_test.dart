import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/notification_center_filter.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

void main() {
  final now = DateTime(2025, 2, 10);

  NotifiedItem movie({DateTime? releaseDate}) => NotifiedItem(
    tmdbId: 1,
    type: MediaType.movie,
    title: 'Movie',
    releaseDate: releaseDate,
  );

  NotifiedItem tv({
    required int tmdbId,
    DateTime? releaseDate,
    int? season,
    int? episode,
  }) => NotifiedItem(
    tmdbId: tmdbId,
    type: MediaType.tv,
    title: 'Show',
    releaseDate: releaseDate,
    seasonNumber: season,
    episodeNumber: episode,
  );

  SeenItem seen({
    int tmdbId = 1,
    MediaType type = MediaType.tv,
    DateTime? seenDate,
    int? season,
    int? episode,
  }) => SeenItem(
    tmdbId: tmdbId,
    type: type,
    title: 'T',
    seenDate: seenDate ?? now,
    seasonNumber: season,
    episodeNumber: episode,
  );

  group('filterReleases', () {
    test('should omit a movie already seen', () {
      final result = filterReleases(
        items: [movie()],
        seenItems: [seen(tmdbId: 1, type: MediaType.movie)],
        now: now,
      );

      expect(result.visible, isEmpty);
      expect(result.omitted.single.reason, ReleaseOmissionReason.alreadySeen);
    });

    test('should keep a tv episode that is not the exact seen episode', () {
      final result = filterReleases(
        items: [tv(tmdbId: 2, releaseDate: now, season: 1, episode: 2)],
        seenItems: [seen(tmdbId: 2, season: 1, episode: 1)],
        now: now,
      );

      expect(result.visible.length, 1);
      expect(result.omitted, isEmpty);
    });

    test('should omit the exact tv episode once it is seen', () {
      final result = filterReleases(
        items: [tv(tmdbId: 2, releaseDate: now, season: 1, episode: 2)],
        seenItems: [seen(tmdbId: 2, season: 1, episode: 2)],
        now: now,
      );

      expect(result.visible, isEmpty);
      expect(result.omitted.single.reason, ReleaseOmissionReason.alreadySeen);
    });

    test('should omit tv episodes older than 30 days', () {
      final result = filterReleases(
        items: [
          tv(
            tmdbId: 3,
            releaseDate: now.subtract(const Duration(days: 31)),
            season: 1,
            episode: 1,
          ),
        ],
        seenItems: const [],
        now: now,
      );

      expect(result.visible, isEmpty);
      expect(
        result.omitted.single.reason,
        ReleaseOmissionReason.olderThan30Days,
      );
    });

    test('should keep tv episodes within 30 days', () {
      final result = filterReleases(
        items: [
          tv(
            tmdbId: 3,
            releaseDate: now.subtract(const Duration(days: 29)),
            season: 1,
            episode: 1,
          ),
        ],
        seenItems: const [],
        now: now,
      );

      expect(result.visible.length, 1);
      expect(result.omitted, isEmpty);
    });

    test('should keep tv releases at exactly the 30 day boundary', () {
      final result = filterReleases(
        items: [
          tv(
            tmdbId: 3,
            releaseDate: now.subtract(const Duration(days: 30)),
            season: 1,
            episode: 1,
          ),
        ],
        seenItems: const [],
        now: now,
      );

      expect(result.visible.length, 1);
      expect(result.omitted, isEmpty);
    });

    test('should keep movies regardless of age', () {
      final result = filterReleases(
        items: [movie(releaseDate: now.subtract(const Duration(days: 400)))],
        seenItems: const [],
        now: now,
      );

      expect(result.visible.length, 1);
      expect(result.omitted, isEmpty);
    });

    test('should keep tv entries without a release date', () {
      final result = filterReleases(
        items: [tv(tmdbId: 4, season: 2, episode: 1)],
        seenItems: const [],
        now: now,
      );

      expect(result.visible.length, 1);
      expect(result.omitted, isEmpty);
    });
  });
}
