import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/history_grouping.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });
  group('formatHistoryDuration', () {
    test('returns empty string for null or zero or negative', () {
      expect(formatHistoryDuration(null), '');
      expect(formatHistoryDuration(0), '');
      expect(formatHistoryDuration(-10), '');
    });

    test('formats minutes under an hour as X min', () {
      expect(formatHistoryDuration(50), '50 min');
      expect(formatHistoryDuration(1), '1 min');
      expect(formatHistoryDuration(59), '59 min');
    });

    test('formats exact hours as X h', () {
      expect(formatHistoryDuration(60), '1 h');
      expect(formatHistoryDuration(120), '2 h');
      expect(formatHistoryDuration(180), '3 h');
    });

    test('formats hours and remaining minutes as X h Y', () {
      expect(formatHistoryDuration(115), '1 h 55');
      expect(formatHistoryDuration(215), '3 h 35');
      expect(formatHistoryDuration(90), '1 h 30');
    });
  });

  group('formatHistoryDayTitle', () {
    final now = DateTime(2026, 11, 16, 15, 30);

    test('returns today label when date is on same day as now', () {
      final todayMorning = DateTime(2026, 11, 16, 0, 1);
      expect(
        formatHistoryDayTitle(
          todayMorning,
          now,
          locale: 'fr',
          todayLabel: "Aujourd'hui",
          yesterdayLabel: 'Hier',
        ),
        "Aujourd'hui",
      );
    });

    test('returns yesterday label when date is one day before now', () {
      final yesterdayNight = DateTime(2026, 11, 15, 23, 59);
      expect(
        formatHistoryDayTitle(
          yesterdayNight,
          now,
          locale: 'fr',
          todayLabel: "Aujourd'hui",
          yesterdayLabel: 'Hier',
        ),
        'Hier',
      );
    });

    test('returns localized long date when older than yesterday', () {
      final olderDate = DateTime(2026, 11, 14, 12);
      final formatted = formatHistoryDayTitle(
        olderDate,
        now,
        locale: 'fr',
        todayLabel: "Aujourd'hui",
        yesterdayLabel: 'Hier',
      );
      expect(formatted, contains('14'));
      expect(formatted, contains('novembre'));
      expect(formatted, contains('2026'));
    });
  });

  group('groupSeenItemsByDay', () {
    test('groups items watched on the same day together', () {
      final day = DateTime(2026, 11, 16);
      final items = [
        SeenItem(
          id: 1,
          tmdbId: 101,
          title: 'Movie 1',
          type: MediaType.movie,
          seenDate: DateTime(2026, 11, 16, 21),
          runtime: 115, // 1h 55
        ),
        SeenItem(
          id: 2,
          tmdbId: 201,
          title: 'Series S1 E1',
          type: MediaType.tv,
          seenDate: DateTime(2026, 11, 16, 20),
          seasonNumber: 1,
          episodeNumber: 1,
          runtime: 50,
        ),
        SeenItem(
          id: 3,
          tmdbId: 201,
          title: 'Series S1 E2',
          type: MediaType.tv,
          seenDate: DateTime(2026, 11, 16, 19),
          seasonNumber: 1,
          episodeNumber: 2,
          runtime: 50,
        ),
      ];

      final groups = groupSeenItemsByDay(items);
      expect(groups.length, 1);

      final group = groups.first;
      expect(group.date, day);
      expect(group.itemCount, 3);
      // 2 episodes of 50 min and 1 movie of 1h55 -> 215 min -> 3 h 35
      expect(group.totalRuntimeMinutes, 215);
      expect(formatHistoryDuration(group.totalRuntimeMinutes), '3 h 35');
      expect(group.hasAnyKnownRuntime, isTrue);
    });

    test('handles midnight boundary and year transition correctly', () {
      final items = [
        SeenItem(
          id: 1,
          tmdbId: 101,
          title: 'New Year Movie',
          type: MediaType.movie,
          seenDate: DateTime(2026, 1, 1, 0, 1),
          runtime: 120,
        ),
        SeenItem(
          id: 2,
          tmdbId: 102,
          title: 'New Year Eve Movie',
          type: MediaType.movie,
          seenDate: DateTime(2025, 12, 31, 23, 59),
          runtime: 90,
        ),
      ];

      final groups = groupSeenItemsByDay(items);
      expect(groups.length, 2);

      expect(groups[0].date, DateTime(2026));
      expect(groups[0].itemCount, 1);
      expect(groups[0].totalRuntimeMinutes, 120);

      expect(groups[1].date, DateTime(2025, 12, 31));
      expect(groups[1].itemCount, 1);
      expect(groups[1].totalRuntimeMinutes, 90);
    });

    test('handles null and zero runtimes without failing', () {
      final items = [
        SeenItem(
          id: 1,
          tmdbId: 101,
          title: 'Unknown duration',
          type: MediaType.movie,
          seenDate: DateTime(2026, 11, 16, 14),
        ),
        SeenItem(
          id: 2,
          tmdbId: 102,
          title: 'Zero duration',
          type: MediaType.movie,
          seenDate: DateTime(2026, 11, 16, 15),
          runtime: 0,
        ),
      ];

      final groups = groupSeenItemsByDay(items);
      expect(groups.length, 1);
      expect(groups.first.itemCount, 2);
      expect(groups.first.totalRuntimeMinutes, 0);
      expect(groups.first.hasAnyKnownRuntime, isFalse);
      expect(formatHistoryDuration(groups.first.totalRuntimeMinutes), '');
    });
  });

  group('aggregateHistoryLibraryEntries', () {
    test(
      'deduplicates items by title and calculates unique episodes and entries',
      () {
        final items = [
          // Show 1: watched S1 E1 twice and S1 E2 once
          SeenItem(
            id: 1,
            tmdbId: 100,
            title: 'My Show',
            type: MediaType.tv,
            seenDate: DateTime(2026, 11, 16, 20),
            seasonNumber: 1,
            episodeNumber: 2,
          ),
          SeenItem(
            id: 2,
            tmdbId: 100,
            title: 'My Show',
            type: MediaType.tv,
            seenDate: DateTime(2026, 11, 15, 20),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
          SeenItem(
            id: 3,
            tmdbId: 100,
            title: 'My Show',
            type: MediaType.tv,
            seenDate: DateTime(2026, 11, 14, 20),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
          // Movie 1: watched twice
          SeenItem(
            id: 4,
            tmdbId: 200,
            title: 'My Movie',
            type: MediaType.movie,
            seenDate: DateTime(2026, 11, 16, 22),
          ),
          SeenItem(
            id: 5,
            tmdbId: 200,
            title: 'My Movie',
            type: MediaType.movie,
            seenDate: DateTime(2026, 10, 10, 20),
          ),
        ];

        final entries = aggregateHistoryLibraryEntries(items);
        expect(entries.length, 2);

        final showEntry = entries.firstWhere(
          (e) => e.latestItem.type == MediaType.tv,
        );
        expect(showEntry.latestItem.title, 'My Show');
        expect(showEntry.totalEntries, 3);
        expect(showEntry.uniqueEpisodesCount, 2); // E1 and E2

        final movieEntry = entries.firstWhere(
          (e) => e.latestItem.type == MediaType.movie,
        );
        expect(movieEntry.latestItem.title, 'My Movie');
        expect(movieEntry.totalEntries, 2);
      },
    );
  });
}
