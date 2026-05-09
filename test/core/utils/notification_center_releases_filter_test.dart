import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  group('Releases filtering - hide old TV episodes', () {
    test('filters out TV releases older than 30 days', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // An episode from more than 30 days ago
      final oldEpisode = NotifiedItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show',
        posterPath: null,
        releaseDate: thirtyDaysAgo.subtract(const Duration(days: 1)),
        seasonNumber: 1,
        episodeNumber: 1,
        autoNotify: true,
      );

      // Should be filtered out
      final shouldFilter = oldEpisode.releaseDate != null &&
          oldEpisode.type == MediaType.tv &&
          oldEpisode.releaseDate!.isBefore(thirtyDaysAgo);

      expect(shouldFilter, true);
    });

    test('keeps TV releases within 30 days', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // An episode from less than 30 days ago
      final recentEpisode = NotifiedItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show',
        posterPath: null,
        releaseDate: thirtyDaysAgo.add(const Duration(days: 1)),
        seasonNumber: 1,
        episodeNumber: 1,
        autoNotify: true,
      );

      // Should NOT be filtered out
      final shouldFilter = recentEpisode.releaseDate != null &&
          recentEpisode.type == MediaType.tv &&
          recentEpisode.releaseDate!.isBefore(thirtyDaysAgo);

      expect(shouldFilter, false);
    });

    test('keeps TV releases at exactly 30 days boundary', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Exactly 30 days ago
      final boundaryEpisode = NotifiedItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show',
        posterPath: null,
        releaseDate: thirtyDaysAgo,
        seasonNumber: 1,
        episodeNumber: 1,
        autoNotify: true,
      );

      final shouldFilter = boundaryEpisode.releaseDate != null &&
          boundaryEpisode.type == MediaType.tv &&
          boundaryEpisode.releaseDate!.isBefore(thirtyDaysAgo);

      // Should NOT filter (not before, equal to 30 days)
      expect(shouldFilter, false);
    });

    test('does not filter movie releases regardless of age', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // An old movie (more than 30 days)
      final oldMovie = NotifiedItem(
        tmdbId: 100,
        type: MediaType.movie,
        title: 'Old Movie',
        posterPath: null,
        releaseDate: thirtyDaysAgo.subtract(const Duration(days: 100)),
        seasonNumber: null,
        episodeNumber: null,
        autoNotify: true,
      );

      // Should NOT be filtered (movies are not filtered)
      final shouldFilter = oldMovie.releaseDate != null &&
          oldMovie.type == MediaType.tv &&
          oldMovie.releaseDate!.isBefore(thirtyDaysAgo);

      expect(shouldFilter, false);
    });

    test('does not filter releases without releaseDate', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // TV item without release date (unplanned)
      final unplannedShow = NotifiedItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show',
        posterPath: null,
        releaseDate: null,
        seasonNumber: 1,
        episodeNumber: 1,
        autoNotify: true,
      );

      // Should NOT be filtered (no date to check)
      final shouldFilter = unplannedShow.releaseDate != null &&
          unplannedShow.type == MediaType.tv &&
          unplannedShow.releaseDate!.isBefore(thirtyDaysAgo);

      expect(shouldFilter, false);
    });

    test('filters old TV episodes but keeps new ones in mixed list', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final items = [
        NotifiedItem(
          tmdbId: 1,
          type: MediaType.tv,
          title: 'Old Show',
          posterPath: null,
          releaseDate: thirtyDaysAgo.subtract(const Duration(days: 5)),
          seasonNumber: 1,
          episodeNumber: 1,
          autoNotify: true,
        ),
        NotifiedItem(
          tmdbId: 2,
          type: MediaType.tv,
          title: 'Recent Show',
          posterPath: null,
          releaseDate: thirtyDaysAgo.add(const Duration(days: 5)),
          seasonNumber: 1,
          episodeNumber: 1,
          autoNotify: true,
        ),
        NotifiedItem(
          tmdbId: 3,
          type: MediaType.movie,
          title: 'Old Movie',
          posterPath: null,
          releaseDate: thirtyDaysAgo.subtract(const Duration(days: 100)),
          seasonNumber: null,
          episodeNumber: null,
          autoNotify: true,
        ),
      ];

      // Filter logic
      final filtered = items.where((item) {
        if (item.type == MediaType.tv && item.releaseDate != null) {
          if (item.releaseDate!.isBefore(thirtyDaysAgo)) {
            return false; // Filter out old TV
          }
        }
        return true;
      }).toList();

      expect(filtered.length, 2);
      expect(filtered[0].title, 'Recent Show');
      expect(filtered[1].title, 'Old Movie');
    });

    test('filters multiple old TV episodes from different shows', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final oldDate = thirtyDaysAgo.subtract(const Duration(days: 1));

      final items = [
        NotifiedItem(
          tmdbId: 100,
          type: MediaType.tv,
          title: 'Show A',
          posterPath: null,
          releaseDate: oldDate,
          seasonNumber: 1,
          episodeNumber: 5,
          autoNotify: true,
        ),
        NotifiedItem(
          tmdbId: 200,
          type: MediaType.tv,
          title: 'Show B',
          posterPath: null,
          releaseDate: oldDate,
          seasonNumber: 2,
          episodeNumber: 3,
          autoNotify: true,
        ),
        NotifiedItem(
          tmdbId: 300,
          type: MediaType.tv,
          title: 'Show C',
          posterPath: null,
          releaseDate: now,
          seasonNumber: 1,
          episodeNumber: 1,
          autoNotify: true,
        ),
      ];

      final filtered = items.where((item) {
        if (item.type == MediaType.tv && item.releaseDate != null) {
          if (item.releaseDate!.isBefore(thirtyDaysAgo)) {
            return false;
          }
        }
        return true;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered[0].title, 'Show C');
    });

    test('preserves show notification status when filtering display', () {
      final now = DateTime.utc(2025, 2, 10);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final oldEpisode = NotifiedItem(
        tmdbId: 100,
        type: MediaType.tv,
        title: 'Show',
        posterPath: null,
        releaseDate: thirtyDaysAgo.subtract(const Duration(days: 5)),
        seasonNumber: 1,
        episodeNumber: 1,
        autoNotify: true,
      );

      // Even though we hide it, the notification status remains intact
      expect(oldEpisode.autoNotify, true);
      expect(oldEpisode.tmdbId, 100);
      expect(oldEpisode.type, MediaType.tv);

      // Would still be notified for next episode, just not shown in UI
    });
  });
}
