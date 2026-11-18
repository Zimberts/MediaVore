import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/list_intersection_calculator.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';

void main() {
  group('ListIntersectionCalculator', () {
    test('computes intersection matching on both ID and mediaType', () {
      final listA = [
        const SharedMediaEntry(1, MediaType.movie),
        const SharedMediaEntry(2, MediaType.movie),
        const SharedMediaEntry(100, MediaType.movie), // movie 100
        const SharedMediaEntry(200, MediaType.tv),
      ];

      final listB = [
        const SharedMediaEntry(
          100,
          MediaType.tv,
        ), // tv 100 (same ID as movie, different type)
        const SharedMediaEntry(2, MediaType.movie), // common
        const SharedMediaEntry(200, MediaType.tv), // common
        const SharedMediaEntry(5, MediaType.movie),
      ];

      final result = ListIntersectionCalculator.intersect(
        listA: listA,
        listB: listB,
      );

      expect(result.isEmpty, isFalse);
      expect(result.totalCount, 2);
      expect(result.commonEntries, [
        const SharedMediaEntry(2, MediaType.movie),
        const SharedMediaEntry(200, MediaType.tv),
      ]);
    });

    test('distinguishes seen and unseen items in common', () {
      final listA = [
        const SharedMediaEntry(1, MediaType.movie),
        const SharedMediaEntry(2, MediaType.movie),
        const SharedMediaEntry(3, MediaType.movie),
      ];

      final listB = [
        const SharedMediaEntry(1, MediaType.movie),
        const SharedMediaEntry(2, MediaType.movie),
        const SharedMediaEntry(3, MediaType.movie),
      ];

      final seenKeys = {(2, MediaType.movie)};

      final result = ListIntersectionCalculator.intersect(
        listA: listA,
        listB: listB,
        seenKeys: seenKeys,
      );

      expect(result.totalCount, 3);
      expect(result.seenCount, 1);
      expect(result.unseenCommonEntries, [
        const SharedMediaEntry(1, MediaType.movie),
        const SharedMediaEntry(3, MediaType.movie),
      ]);
    });

    test('returns empty result when there is no intersection', () {
      final listA = [
        const SharedMediaEntry(1, MediaType.movie),
        const SharedMediaEntry(2, MediaType.tv),
      ];
      final listB = [
        const SharedMediaEntry(3, MediaType.movie),
        const SharedMediaEntry(4, MediaType.tv),
      ];

      final result = ListIntersectionCalculator.intersect(
        listA: listA,
        listB: listB,
      );

      expect(result.isEmpty, isTrue);
      expect(result.totalCount, 0);
      expect(result.commonEntries, isEmpty);
      expect(result.unseenCommonEntries, isEmpty);
      expect(result.seenCount, 0);
    });

    test('deduplicates items if listA contained duplicates', () {
      final listA = [
        const SharedMediaEntry(1, MediaType.movie),
        const SharedMediaEntry(1, MediaType.movie),
      ];
      final listB = [const SharedMediaEntry(1, MediaType.movie)];

      final result = ListIntersectionCalculator.intersect(
        listA: listA,
        listB: listB,
      );

      expect(result.totalCount, 1);
      expect(result.commonEntries.length, 1);
    });
  });
}
