import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/unseen_episodes.dart';

void main() {
  group('findPreviousUnseenEpisodes', () {
    final now = DateTime(2026, 11, 16);

    test('proposes 4 episodes when checking S2 E5 with S1 complete and S2 E1-E4 unseen', () {
      final allEpisodes = <CandidateEpisode>[
        // Season 0 (specials)
        const CandidateEpisode(seasonNumber: 0, episodeNumber: 1, airDate: '2023-01-01'),
        // Season 1
        const CandidateEpisode(seasonNumber: 1, episodeNumber: 1, airDate: '2023-01-02'),
        const CandidateEpisode(seasonNumber: 1, episodeNumber: 2, airDate: '2023-01-09'),
        // Season 2
        const CandidateEpisode(seasonNumber: 2, episodeNumber: 1, airDate: '2024-01-02'),
        const CandidateEpisode(seasonNumber: 2, episodeNumber: 2, airDate: '2024-01-09'),
        const CandidateEpisode(seasonNumber: 2, episodeNumber: 3, airDate: '2024-01-16'),
        const CandidateEpisode(seasonNumber: 2, episodeNumber: 4, airDate: '2024-01-23'),
        const CandidateEpisode(seasonNumber: 2, episodeNumber: 5, airDate: '2024-01-30'),
        const CandidateEpisode(seasonNumber: 2, episodeNumber: 6, airDate: '2024-02-06'),
      ];

      final seenEpisodeKeys = {'1:1', '1:2'}; // S1 complete

      final result = findPreviousUnseenEpisodes(
        targetSeason: 2,
        targetEpisode: 5,
        allEpisodes: allEpisodes,
        seenEpisodeKeys: seenEpisodeKeys,
        now: now,
      );

      expect(result.length, 4);
      expect(result.map((e) => 'S${e.seasonNumber}E${e.episodeNumber}').toList(), [
        'S2E1',
        'S2E2',
        'S2E3',
        'S2E4',
      ]);
    });

    test('excludes un-aired episodes even if anterior in numbering', () {
      final allEpisodes = <CandidateEpisode>[
        const CandidateEpisode(seasonNumber: 1, episodeNumber: 1, airDate: '2026-11-01'),
        const CandidateEpisode(seasonNumber: 1, episodeNumber: 2, airDate: '2026-12-01'), // Future
        const CandidateEpisode(seasonNumber: 1, episodeNumber: 3, airDate: '2026-12-15'), // Target
      ];

      final result = findPreviousUnseenEpisodes(
        targetSeason: 1,
        targetEpisode: 3,
        allEpisodes: allEpisodes,
        seenEpisodeKeys: <String>{},
        now: now,
      );

      expect(result.length, 1);
      expect(result.first.episodeNumber, 1);
    });

    test('ignores season 0 specials', () {
      final allEpisodes = <CandidateEpisode>[
        const CandidateEpisode(seasonNumber: 0, episodeNumber: 1, airDate: '2020-01-01'),
        const CandidateEpisode(seasonNumber: 1, episodeNumber: 1, airDate: '2021-01-01'),
        const CandidateEpisode(seasonNumber: 1, episodeNumber: 2, airDate: '2021-01-08'),
      ];

      final result = findPreviousUnseenEpisodes(
        targetSeason: 1,
        targetEpisode: 2,
        allEpisodes: allEpisodes,
        seenEpisodeKeys: <String>{},
        now: now,
      );

      expect(result.length, 1);
      expect(result.first.seasonNumber, 1);
      expect(result.first.episodeNumber, 1);
    });
  });
}
