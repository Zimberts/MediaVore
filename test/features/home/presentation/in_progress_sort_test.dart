import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/home/presentation/in_progress_sort.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

final _now = DateTime(2026, 11, 14);

InProgressItem _item(
  int id,
  String? title, {
  double? progress,
  int daysAgo = 1,
}) => InProgressItem(
  next: QuickAddItem(
    tmdbId: id,
    type: MediaType.tv,
    seasonNumber: 1,
    episodeNumber: 2,
    insertedAt: _now,
    title: title,
  ),
  seenEpisodes: 1,
  totalEpisodes: progress == null ? null : 10,
  progress: progress,
  lastActivity: _now.subtract(Duration(days: daysAgo)),
  paused: daysAgo > 30,
);

List<int> _ids(List<InProgressItem> items) => [
  for (final item in items) item.tmdbId,
];

void main() {
  group('sortInProgress', () {
    final items = [
      _item(1, 'severance', progress: 0.2, daysAgo: 3),
      _item(2, 'Andor', progress: 0.9, daysAgo: 40),
      _item(3, 'The Bear', daysAgo: 1),
      _item(4, 'Dark', progress: 0.9, daysAgo: 2),
    ];

    test('should put the most recent activity first', () {
      expect(_ids(sortInProgress(items, InProgressSort.recent)), [3, 4, 1, 2]);
    });

    test('should put the largest progress first and the unknown last', () {
      expect(_ids(sortInProgress(items, InProgressSort.almostDone)), [
        4,
        2,
        1,
        3,
      ]);
    });

    test('should sort by title whatever the case', () {
      expect(_ids(sortInProgress(items, InProgressSort.alphabetical)), [
        2,
        4,
        1,
        3,
      ]);
    });

    test('should break ties by activity then id, without a title', () {
      final untitled = [
        _item(9, null, daysAgo: 5),
        _item(7, null, daysAgo: 5),
        _item(8, null, daysAgo: 1),
      ];
      expect(_ids(sortInProgress(untitled, InProgressSort.alphabetical)), [
        8,
        7,
        9,
      ]);
    });

    test('should leave the given list untouched', () {
      sortInProgress(items, InProgressSort.alphabetical);
      expect(_ids(items), [1, 2, 3, 4]);
    });
  });
}
