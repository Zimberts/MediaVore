import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/watch_tail.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

SeenItemModel seen(int season, int episode, {DateTime? date, int tmdbId = 1}) {
  return SeenItemModel(
    tmdbId: tmdbId,
    type: 'tv',
    title: 'Show',
    seenDate: date ?? DateTime(2024, 1, 1),
    seasonNumber: season,
    episodeNumber: episode,
  );
}

EpisodeRef ep(int season, int episode, {DateTime? airDate, int? runtime}) {
  return EpisodeRef(
    seasonNumber: season,
    episodeNumber: episode,
    airDate: airDate,
    runtime: runtime,
  );
}

void main() {
  group('findLatestTail', () {
    test('should return null when there are no episode entries', () {
      expect(findLatestTail(const []), isNull);
    });

    test('should ignore entries without season/episode info', () {
      final items = [
        SeenItemModel(
          tmdbId: 1,
          type: 'tv',
          title: 'Show',
          seenDate: DateTime(2024, 5, 1),
        ),
      ];

      expect(findLatestTail(items), isNull);
    });

    test('should pick the entry with the greatest seenDate', () {
      final items = [
        seen(1, 1, date: DateTime(2024, 1, 1)),
        seen(3, 4, date: DateTime(2024, 6, 1)),
        seen(2, 1, date: DateTime(2024, 3, 1)),
      ];

      final tail = findLatestTail(items);

      expect(tail, isNotNull);
      expect(tail!.seasonNumber, 3);
      expect(tail.episodeNumber, 4);
    });

    test('should break ties by higher season then higher episode', () {
      final date = DateTime(2024, 2, 2);
      final items = [
        seen(2, 3, date: date),
        seen(3, 1, date: date),
        seen(2, 4, date: date),
      ];

      final tail = findLatestTail(items);

      expect(tail!.seasonNumber, 3);
      expect(tail.episodeNumber, 1);
    });
  });

  group('findNextEpisodeAfterTail', () {
    final tail = WatchTail(
      seasonNumber: 4,
      episodeNumber: 5,
      seenDate: DateTime(2024, 6, 1),
    );

    test('should return the next episode in the same season', () {
      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: [
          ep(4, 5, airDate: DateTime(2024, 5, 1)),
          ep(4, 6, airDate: DateTime(2024, 6, 8), runtime: 42),
        ],
        seenEpisodeKeys: const {},
      );

      expect(next, isNotNull);
      expect(next!.seasonNumber, 4);
      expect(next.episodeNumber, 6);
      expect(next.runtime, 42);
    });

    test('should anchor to the tail streak, not an earlier unseen gap', () {
      // Bug scenario: user watched S1E1 then jumped to S4E5. Releases must point
      // at S4E6, never back at S1E2.
      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: [
          ep(1, 1, airDate: DateTime(2015, 1, 1)),
          ep(1, 2, airDate: DateTime(2015, 1, 8)),
          ep(4, 6, airDate: DateTime(2024, 6, 8)),
        ],
        seenEpisodeKeys: const {},
      );

      expect(next!.seasonNumber, 4);
      expect(next.episodeNumber, 6);
    });

    test('should move to the next season when the current one is finished', () {
      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: [
          ep(4, 5, airDate: DateTime(2024, 5, 1)),
          ep(5, 1, airDate: DateTime(2024, 9, 1)),
        ],
        seenEpisodeKeys: const {},
      );

      expect(next!.seasonNumber, 5);
      expect(next.episodeNumber, 1);
    });

    test('should skip season 0 specials', () {
      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: [
          ep(0, 1, airDate: DateTime(2024, 6, 2)),
          ep(4, 6, airDate: DateTime(2024, 6, 8)),
        ],
        seenEpisodeKeys: const {},
      );

      expect(next!.seasonNumber, 4);
      expect(next.episodeNumber, 6);
    });

    test('should skip episodes already seen', () {
      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: [
          ep(4, 6, airDate: DateTime(2024, 6, 8)),
          ep(4, 7, airDate: DateTime(2024, 6, 15)),
        ],
        seenEpisodeKeys: {episodeKey(4, 6)},
      );

      expect(next!.episodeNumber, 7);
    });

    test('should return an undated episode so it shows as date TBA', () {
      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: [ep(5, 1)],
        seenEpisodeKeys: const {},
      );

      expect(next, isNotNull);
      expect(next!.seasonNumber, 5);
      expect(next.airDate, isNull);
    });

    test('should return null when nothing remains after the tail', () {
      final next = findNextEpisodeAfterTail(
        tail: tail,
        episodes: [
          ep(4, 1, airDate: DateTime(2024, 1, 1)),
          ep(4, 5, airDate: DateTime(2024, 5, 1)),
        ],
        seenEpisodeKeys: const {},
      );

      expect(next, isNull);
    });
  });
}
