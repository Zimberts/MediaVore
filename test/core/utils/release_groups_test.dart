import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/release_groups.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

NotifiedItem _item(
  int id,
  DateTime? date, {
  MediaType type = MediaType.movie,
  String? title,
  int? season,
  int? episode,
}) => NotifiedItem(
  tmdbId: id,
  type: type,
  title: title ?? 'Title $id',
  releaseDate: date,
  seasonNumber: season,
  episodeNumber: episode,
);

List<int> _ids(List<NotifiedItem> items) => [
  for (final item in items) item.tmdbId,
];

void main() {
  // Saturday, in the evening: the injected clock.
  final now = DateTime(2026, 11, 14, 21, 30);

  group('releasePeriodOf', () {
    test('should put a release of today in "this week" at any time', () {
      for (final date in [
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 14, 12),
        DateTime(2026, 11, 14, 23, 59, 59),
      ]) {
        expect(releasePeriodOf(date, now), ReleasePeriod.thisWeek);
      }
      expect(
        releasePeriodOf(DateTime(2026, 11, 14), DateTime(2026, 11, 14)),
        ReleasePeriod.thisWeek,
      );
    });

    test('should put yesterday in "released", even late in the evening', () {
      expect(
        releasePeriodOf(DateTime(2026, 11, 13, 23, 59, 59), now),
        ReleasePeriod.released,
      );
      expect(
        releasePeriodOf(DateTime(2025, 1, 1), now),
        ReleasePeriod.released,
      );
    });

    test('should end "this week" after 7 days, today included', () {
      expect(
        releasePeriodOf(DateTime(2026, 11, 20, 23, 59), now),
        ReleasePeriod.thisWeek,
      );
      expect(
        releasePeriodOf(DateTime(2026, 11, 21), now),
        ReleasePeriod.thisMonth,
      );
    });

    test('should end "this month" after 31 days, across the month end', () {
      expect(
        releasePeriodOf(DateTime(2026, 12, 14, 23, 59), now),
        ReleasePeriod.thisMonth,
      );
      expect(releasePeriodOf(DateTime(2026, 12, 15), now), ReleasePeriod.later);
      expect(releasePeriodOf(DateTime(2027, 6, 1), now), ReleasePeriod.later);
    });

    test('should cross the end of the year', () {
      final newYearsEve = DateTime(2026, 12, 31, 8);
      expect(
        releasePeriodOf(DateTime(2027, 1, 6), newYearsEve),
        ReleasePeriod.thisWeek,
      );
      expect(
        releasePeriodOf(DateTime(2027, 1, 7), newYearsEve),
        ReleasePeriod.thisMonth,
      );
      expect(
        releasePeriodOf(DateTime(2027, 1, 31), newYearsEve),
        ReleasePeriod.later,
      );
    });

    test('should compare calendar days of the local time zone', () {
      // The same instant, given in UTC: its local day decides.
      final instant = DateTime(2026, 11, 14, 0, 30).toUtc();
      expect(releasePeriodOf(instant, now), ReleasePeriod.thisWeek);

      final lastNight = DateTime(2026, 11, 13, 23, 30).toUtc();
      expect(releasePeriodOf(lastNight, now), ReleasePeriod.released);

      // A clock given in UTC is read in local time too.
      expect(
        releasePeriodOf(DateTime(2026, 11, 14), now.toUtc()),
        ReleasePeriod.thisWeek,
      );
    });

    test('should accept other window lengths', () {
      expect(
        releasePeriodOf(DateTime(2026, 11, 16), now, weekDays: 2),
        ReleasePeriod.thisMonth,
      );
      expect(
        releasePeriodOf(DateTime(2026, 11, 20), now, weekDays: 2, monthDays: 5),
        ReleasePeriod.later,
      );
    });
  });

  group('groupReleases', () {
    final items = [
      _item(1, DateTime(2027, 3, 1)),
      _item(
        2,
        DateTime(2026, 11, 14),
        type: MediaType.tv,
        season: 2,
        episode: 4,
      ),
      _item(3, DateTime(2026, 11, 2)),
      _item(4, null, type: MediaType.tv, title: 'Returning'),
      _item(
        5,
        DateTime(2026, 11, 30),
        type: MediaType.tv,
        season: 1,
        episode: 1,
      ),
      _item(6, null, title: 'Planned'),
      _item(7, DateTime(2026, 11, 18)),
      _item(8, DateTime(2026, 12, 10)),
      _item(
        9,
        null,
        type: MediaType.tv,
        title: 'To date',
        season: 3,
        episode: 1,
      ),
    ];

    test('should split by period, oldest first', () {
      final groups = groupReleases(items, now: now);

      expect(_ids(groups.of(ReleasePeriod.released)), [3]);
      expect(_ids(groups.of(ReleasePeriod.thisWeek)), [2, 7]);
      expect(_ids(groups.of(ReleasePeriod.thisMonth)), [5, 8]);
      expect(_ids(groups.of(ReleasePeriod.later)), [1]);
      expect(_ids(groups.dated), [3, 2, 7, 5, 8, 1]);
      expect(groups.datedCount, 6);
    });

    test('should keep undated releases apart: episode, series, film', () {
      final groups = groupReleases(items, now: now);

      expect(_ids(groups.undated), [9, 4, 6]);
    });

    test('should group what is not out yet by calendar month', () {
      final months = groupReleases(items, now: now).upcomingByMonth;

      expect(
        [for (final m in months) m.month],
        [DateTime(2026, 11), DateTime(2026, 12), DateTime(2027, 3)],
      );
      expect(_ids(months[0].items), [2, 7, 5]);
      expect(_ids(months[1].items), [8]);
      expect(_ids(months[2].items), [1]);
    });

    test('should split on the first day of a month, not on 30 days', () {
      final months = groupReleases([
        _item(1, DateTime(2026, 11, 30, 23, 59)),
        _item(2, DateTime(2026, 12, 1)),
      ], now: now).upcomingByMonth;

      expect(months, hasLength(2));
      expect(_ids(months[0].items), [1]);
      expect(_ids(months[1].items), [2]);
    });

    test('should keep a single type, with consistent counts', () {
      final all = groupReleases(items, now: now);
      final films = groupReleases(items, now: now, type: MediaType.movie);
      final series = groupReleases(items, now: now, type: MediaType.tv);

      expect(_ids(films.dated), [3, 7, 8, 1]);
      expect(_ids(series.dated), [2, 5]);
      expect(films.datedCount + series.datedCount, all.datedCount);
      expect(films.undated.length + series.undated.length, all.undated.length);
    });

    test('should sort releases of the same day by title', () {
      final groups = groupReleases([
        _item(2, DateTime(2026, 11, 15), title: 'Zodiac'),
        _item(1, DateTime(2026, 11, 15), title: 'Alien'),
      ], now: now);

      expect(_ids(groups.of(ReleasePeriod.thisWeek)), [1, 2]);
    });

    test('should be empty without releases', () {
      final groups = groupReleases(const [], now: now);

      expect(groups.datedCount, 0);
      expect(groups.undated, isEmpty);
      expect(groups.upcomingByMonth, isEmpty);
      expect(groups.of(ReleasePeriod.thisWeek), isEmpty);
    });
  });
}
