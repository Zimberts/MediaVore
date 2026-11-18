import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/release_sort.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Period a dated release falls in, relative to today (local time).
enum ReleasePeriod {
  /// Before today: already out, still listed until it is seen.
  released,

  /// Today and the following days, [kReleaseWeekDays] in all.
  thisWeek,

  /// After that, up to [kReleaseMonthDays] days from today.
  thisMonth,

  /// Beyond.
  later,
}

/// Days of "This week", today included: a rolling window, as in the design
/// prototype, not the calendar week.
const int kReleaseWeekDays = 7;

/// Days of "This week" and "This month" together, today included.
const int kReleaseMonthDays = 31;

/// Calendar day of [date] in the local time zone.
DateTime _localDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Period of a release dated [date], seen from [now].
///
/// Only calendar days count, in the local time zone: a release dated today
/// is in [ReleasePeriod.thisWeek] whatever the time. Bounds are computed on
/// calendar days, so a daylight saving change does not shift them.
ReleasePeriod releasePeriodOf(
  DateTime date,
  DateTime now, {
  int weekDays = kReleaseWeekDays,
  int monthDays = kReleaseMonthDays,
}) {
  final day = _localDay(date);
  final today = _localDay(now);
  if (day.isBefore(today)) return ReleasePeriod.released;
  final weekEnd = DateTime(today.year, today.month, today.day + weekDays);
  if (day.isBefore(weekEnd)) return ReleasePeriod.thisWeek;
  final monthEnd = DateTime(today.year, today.month, today.day + monthDays);
  if (day.isBefore(monthEnd)) return ReleasePeriod.thisMonth;
  return ReleasePeriod.later;
}

/// Releases of one calendar month.
class ReleaseMonth {
  const ReleaseMonth({required this.month, required this.items});

  /// First day of the month, local time.
  final DateTime month;
  final List<NotifiedItem> items;
}

/// Releases split by period, plus the ones without a date.
class ReleaseGroups {
  const ReleaseGroups({required this.byPeriod, required this.undated});

  /// Dated releases of each period, oldest first. Every period has an entry.
  final Map<ReleasePeriod, List<NotifiedItem>> byPeriod;

  /// Releases without a date (renewed, planned, episode to be dated), in the
  /// order of [sortReleases].
  final List<NotifiedItem> undated;

  List<NotifiedItem> of(ReleasePeriod period) => byPeriod[period] ?? const [];

  /// Every dated release, oldest first.
  List<NotifiedItem> get dated => [
    for (final period in ReleasePeriod.values) ...of(period),
  ];

  /// Number of dated releases: the counter of "Upcoming".
  int get datedCount =>
      ReleasePeriod.values.fold(0, (sum, period) => sum + of(period).length);

  /// Releases that are not out yet ([ReleasePeriod.released] excluded), by
  /// calendar month, oldest first.
  List<ReleaseMonth> get upcomingByMonth {
    final months = <ReleaseMonth>[];
    for (final period in ReleasePeriod.values) {
      if (period == ReleasePeriod.released) continue;
      for (final item in of(period)) {
        final date = item.releaseDate!.toLocal();
        final month = DateTime(date.year, date.month);
        if (months.isEmpty || months.last.month != month) {
          months.add(ReleaseMonth(month: month, items: []));
        }
        months.last.items.add(item);
      }
    }
    return months;
  }
}

/// Groups [items] by period seen from [now]; [type] keeps a single media
/// type (`null` = all).
///
/// Pure: pass the releases already filtered (see `filterReleases`).
ReleaseGroups groupReleases(
  Iterable<NotifiedItem> items, {
  required DateTime now,
  MediaType? type,
}) {
  final kept = [
    for (final item in items)
      if (type == null || item.type == type) item,
  ];
  final dated = [
    for (final item in kept)
      if (item.releaseDate != null) item,
  ];
  dated.sort((a, b) {
    final byDate = a.releaseDate!.compareTo(b.releaseDate!);
    if (byDate != 0) return byDate;
    final byTitle = a.title.compareTo(b.title);
    return byTitle != 0 ? byTitle : a.tmdbId.compareTo(b.tmdbId);
  });

  final byPeriod = {
    for (final period in ReleasePeriod.values) period: <NotifiedItem>[],
  };
  for (final item in dated) {
    byPeriod[releasePeriodOf(item.releaseDate!, now)]!.add(item);
  }

  return ReleaseGroups(
    byPeriod: byPeriod,
    undated: sortReleases([
      for (final item in kept)
        if (item.releaseDate == null) item,
    ]),
  );
}
