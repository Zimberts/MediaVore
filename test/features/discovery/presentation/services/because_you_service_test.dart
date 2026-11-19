import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/liked_item_info.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/discovery/presentation/services/because_you_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BecauseYouService - Candidate Selection', () {
    test('prioritizes liked items over watched and in-progress items', () {
      final candidates = BecauseYouService.selectCandidates(
        likedItems: const [
          LikedItemInfo(tmdbId: 10, type: MediaType.movie, title: 'Inception'),
          LikedItemInfo(tmdbId: 20, type: MediaType.tv, title: 'Severance'),
        ],
        seenItems: [
          SeenItem(
            tmdbId: 30,
            type: MediaType.movie,
            title: 'Dune',
            seenDate: DateTime(2026, 1, 1),
          ),
        ],
        inProgressItems: [],
      );

      expect(candidates.length, 2);
      expect(candidates[0].id, 10);
      expect(candidates[0].title, 'Inception');
      expect(candidates[0].reason, BecauseYouReason.liked);
      expect(candidates[1].id, 20);
      expect(candidates[1].reason, BecauseYouReason.liked);
    });

    test(
      'falls back to watched movies and in-progress series sorted chronologically',
      () {
        final candidates = BecauseYouService.selectCandidates(
          likedItems: const [],
          seenItems: [
            SeenItem(
              tmdbId: 1,
              type: MediaType.movie,
              title: 'Older Movie',
              seenDate: DateTime(2026, 1, 1),
            ),
            SeenItem(
              tmdbId: 2,
              type: MediaType.movie,
              title: 'Newer Movie',
              seenDate: DateTime(2026, 1, 10),
            ),
          ],
          inProgressItems: [
            InProgressItem(
              next: QuickAddItem(
                tmdbId: 3,
                type: MediaType.tv,
                title: 'Active Series',
                seasonNumber: 1,
                episodeNumber: 2,
                insertedAt: DateTime(2026, 1, 15),
              ),
              seenEpisodes: 1,
              totalEpisodes: 10,
              progress: 0.1,
              lastActivity: DateTime(2026, 1, 15),
              paused: false,
            ),
          ],
        );

        expect(candidates.length, 3);
        expect(candidates[0].id, 3); // Active Series (Jan 15)
        expect(candidates[0].title, 'Active Series');
        expect(candidates[0].reason, BecauseYouReason.watched);

        expect(candidates[1].id, 2); // Newer Movie (Jan 10)
        expect(candidates[1].title, 'Newer Movie');
        expect(candidates[1].reason, BecauseYouReason.watched);

        expect(candidates[2].id, 1); // Older Movie (Jan 1)
        expect(candidates[2].title, 'Older Movie');
        expect(candidates[2].reason, BecauseYouReason.watched);
      },
    );

    test('returns empty when there is no history or liked items', () {
      final candidates = BecauseYouService.selectCandidates(
        likedItems: const [],
        seenItems: const [],
        inProgressItems: const [],
      );

      expect(candidates, isEmpty);
    });
  });

  group('BecauseYouService - Recommendation Filtering', () {
    final raw = [
      for (var i = 1; i <= 15; i++)
        MediaItem(
          id: i,
          title: 'Movie $i',
          overview: '',
          releaseDate: '2020',
          mediaType: MediaType.movie,
        ),
    ];

    test('excludes seen and list items, caps at 10 items', () {
      final filtered = BecauseYouService.filterRecommendations(
        raw,
        isSeenOrInList: (id, type) => id <= 3, // Exclude 1, 2, 3
      );

      // Remaining: 4 to 13 (10 items)
      expect(filtered.length, 10);
      expect(filtered.map((e) => e.id), isNot(contains(1)));
      expect(filtered.map((e) => e.id), isNot(contains(2)));
      expect(filtered.map((e) => e.id), isNot(contains(3)));
      expect(filtered.first.id, 4);
    });

    test('returns empty list if fewer than 3 items remain after exclusion', () {
      final filtered = BecauseYouService.filterRecommendations(
        raw,
        isSeenOrInList: (id, type) => id > 2, // Only 1 and 2 remain
      );

      expect(filtered, isEmpty);
    });
  });

  group('BecauseYouService - Daily Cache', () {
    test('saves and loads daily cache on the same day', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 11, 18, 14, 0);

      const sampleData = BecauseYouData(
        sourceId: 100,
        sourceType: MediaType.movie,
        sourceTitle: 'Dune',
        reason: BecauseYouReason.liked,
        items: [
          MediaItem(id: 1, title: 'Rec 1', overview: '', releaseDate: ''),
          MediaItem(id: 2, title: 'Rec 2', overview: '', releaseDate: ''),
          MediaItem(id: 3, title: 'Rec 3', overview: '', releaseDate: ''),
        ],
      );

      await BecauseYouService.saveCached(
        prefs: prefs,
        now: now,
        data: sampleData,
      );

      final loaded = await BecauseYouService.loadCached(
        prefs: prefs,
        now: now,
        isSeenOrInList: (id, type) => false,
      );

      expect(loaded, equals(sampleData));

      // Expired date next day
      final tomorrow = DateTime(2026, 11, 19, 9, 0);
      final expired = await BecauseYouService.loadCached(
        prefs: prefs,
        now: tomorrow,
        isSeenOrInList: (id, type) => false,
      );

      expect(expired, isNull);
    });
  });
}
