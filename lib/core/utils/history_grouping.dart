import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

/// Formats a duration in minutes according to the V1 history specification:
/// - null or 0 -> empty string
/// - < 60 min -> "50 min"
/// - multiple of 60 -> "2 h"
/// - hours and remaining minutes -> "3 h 35"
String formatHistoryDuration(int? minutes) {
  if (minutes == null || minutes <= 0) return '';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '$remaining min';
  if (remaining == 0) return '$hours h';
  return '$hours h $remaining';
}

/// Formats the header title of a day group:
/// - "Aujourd'hui" / todayLabel if the date is today
/// - "Hier" / yesterdayLabel if the date is yesterday
/// - Localized long date otherwise (e.g. "12 novembre 2026")
String formatHistoryDayTitle(
  DateTime date,
  DateTime now, {
  required String locale,
  required String todayLabel,
  required String yesterdayLabel,
}) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final normalizedNow = DateTime(now.year, now.month, now.day);
  final differenceInDays = normalizedNow.difference(normalizedDate).inDays;

  if (differenceInDays == 0) {
    return todayLabel;
  }
  if (differenceInDays == 1) {
    return yesterdayLabel;
  }
  try {
    return DateFormat.yMMMMd(locale).format(normalizedDate);
  } catch (_) {
    return DateFormat.yMMMMd().format(normalizedDate);
  }
}

/// A day group in chronological history containing items seen on that day.
class HistoryDayGroup {
  const HistoryDayGroup({
    required this.date,
    required this.items,
    required this.totalRuntimeMinutes,
    required this.hasAnyKnownRuntime,
  });

  /// The normalized calendar day (midnight).
  final DateTime date;

  /// The items watched on this day.
  final List<SeenItem> items;

  /// Number of items watched on this day.
  int get itemCount => items.length;

  /// Total duration in minutes (sum of items where runtime > 0).
  final int totalRuntimeMinutes;

  /// True if at least one item on this day had a known runtime > 0.
  final bool hasAnyKnownRuntime;
}

/// Groups sorted [items] into [HistoryDayGroup]s by calendar day.
///
/// Preserves the order of items within each day.
/// Properly handles midnight boundaries, year transitions, and null/zero runtimes.
List<HistoryDayGroup> groupSeenItemsByDay(List<SeenItem> items) {
  if (items.isEmpty) return const [];

  final List<HistoryDayGroup> groups = [];
  DateTime? currentDay;
  final List<SeenItem> currentItems = [];
  int currentRuntime = 0;
  bool currentHasRuntime = false;

  void flush() {
    if (currentDay != null && currentItems.isNotEmpty) {
      groups.add(
        HistoryDayGroup(
          date: currentDay,
          items: List.unmodifiable(currentItems),
          totalRuntimeMinutes: currentRuntime,
          hasAnyKnownRuntime: currentHasRuntime,
        ),
      );
      currentItems.clear();
      currentRuntime = 0;
      currentHasRuntime = false;
    }
  }

  for (final item in items) {
    final itemDay = DateTime(
      item.seenDate.year,
      item.seenDate.month,
      item.seenDate.day,
    );

    if (currentDay == null || itemDay != currentDay) {
      flush();
      currentDay = itemDay;
    }

    currentItems.add(item);
    if (item.runtime != null && item.runtime! > 0) {
      currentRuntime += item.runtime!;
      currentHasRuntime = true;
    }
  }
  flush();

  return groups;
}

/// Aggregated library view entry for a unique media title.
class HistoryLibraryEntry {
  const HistoryLibraryEntry({
    required this.latestItem,
    required this.totalEntries,
    required this.uniqueEpisodesCount,
  });

  /// The most recent seen entry for this title (holds title, poster, type, etc.).
  final SeenItem latestItem;

  /// Total number of seen entries logged for this title.
  final int totalEntries;

  /// Number of distinct episodes seen (for series).
  final int uniqueEpisodesCount;
}

/// Aggregates [items] for Library view (one entry per title).
///
/// Returns one [HistoryLibraryEntry] per distinct tmdbId + type.
List<HistoryLibraryEntry> aggregateHistoryLibraryEntries(List<SeenItem> items) {
  if (items.isEmpty) return const [];

  final Map<String, List<SeenItem>> groupedByTitle = {};
  for (final item in items) {
    final key = '${item.tmdbId}:${item.type.name}';
    groupedByTitle.putIfAbsent(key, () => []).add(item);
  }

  final List<HistoryLibraryEntry> result = [];
  for (final entryList in groupedByTitle.values) {
    // Sort to find the latest seenDate
    entryList.sort((a, b) => b.seenDate.compareTo(a.seenDate));
    final latest = entryList.first;

    final distinctEpisodes = <String>{};
    for (final item in entryList) {
      if (item.seasonNumber != null && item.episodeNumber != null) {
        distinctEpisodes.add('${item.seasonNumber}:${item.episodeNumber}');
      }
    }

    result.add(
      HistoryLibraryEntry(
        latestItem: latest,
        totalEntries: entryList.length,
        uniqueEpisodesCount: distinctEpisodes.length,
      ),
    );
  }

  return result;
}
