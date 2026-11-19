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

    group('multiIntersect', () {
      test('returns empty when no lists provided', () {
        final result = ListIntersectionCalculator.multiIntersect(lists: []);
        expect(result.commonEntries, isEmpty);
        expect(result.almostEntries, isEmpty);
      });

      test('for 2 participants, computes exact intersection without almost', () {
        final list1 = (
          name: 'Host',
          initials: 'HO',
          entries: const [
            SharedMediaEntry(1, MediaType.movie),
            SharedMediaEntry(2, MediaType.movie),
            SharedMediaEntry(3, MediaType.tv),
          ],
        );
        final list2 = (
          name: 'Friend',
          initials: 'FR',
          entries: const [
            SharedMediaEntry(2, MediaType.movie),
            SharedMediaEntry(3, MediaType.tv),
            SharedMediaEntry(4, MediaType.movie),
          ],
        );

        final result = ListIntersectionCalculator.multiIntersect(
          lists: [list1, list2],
        );

        expect(result.commonEntries, [
          const SharedMediaEntry(2, MediaType.movie),
          const SharedMediaEntry(3, MediaType.tv),
        ]);
        expect(result.almostEntries, isEmpty);
        expect(result.participantInitials['2:movie'], ['HO', 'FR']);
        expect(result.participantInitials['3:tv'], ['HO', 'FR']);
      });

      test('for 3 participants, separates common and almost (in 2 of 3 lists)', () {
        final p1 = (
          name: 'Alice',
          initials: 'AL',
          entries: const [
            SharedMediaEntry(1, MediaType.movie), // in all 3
            SharedMediaEntry(2, MediaType.movie), // in p1, p2
            SharedMediaEntry(3, MediaType.movie), // only in p1
          ],
        );
        final p2 = (
          name: 'Bob',
          initials: 'BO',
          entries: const [
            SharedMediaEntry(1, MediaType.movie), // in all 3
            SharedMediaEntry(2, MediaType.movie), // in p1, p2
            SharedMediaEntry(4, MediaType.tv), // in p2, p3
          ],
        );
        final p3 = (
          name: 'Charlie',
          initials: 'CH',
          entries: const [
            SharedMediaEntry(1, MediaType.movie), // in all 3
            SharedMediaEntry(4, MediaType.tv), // in p2, p3
            SharedMediaEntry(5, MediaType.movie), // only in p3
          ],
        );

        final result = ListIntersectionCalculator.multiIntersect(
          lists: [p1, p2, p3],
        );

        // In all 3: 1:movie
        expect(result.commonEntries, [const SharedMediaEntry(1, MediaType.movie)]);

        // In 2 of 3: 2:movie and 4:tv
        expect(result.almostEntries, [
          const SharedMediaEntry(2, MediaType.movie),
          const SharedMediaEntry(4, MediaType.tv),
        ]);

        expect(result.participantInitials['1:movie'], ['AL', 'BO', 'CH']);
        expect(result.participantInitials['2:movie'], ['AL', 'BO']);
        expect(result.participantInitials['4:tv'], ['BO', 'CH']);
      });

      test('respects typeFilter and hideSeen', () {
        final p1 = (
          name: 'Alice',
          initials: 'AL',
          entries: const [
            SharedMediaEntry(1, MediaType.movie),
            SharedMediaEntry(2, MediaType.tv),
          ],
        );
        final p2 = (
          name: 'Bob',
          initials: 'BO',
          entries: const [
            SharedMediaEntry(1, MediaType.movie),
            SharedMediaEntry(2, MediaType.tv),
          ],
        );

        // Filter by TV only
        final tvOnly = ListIntersectionCalculator.multiIntersect(
          lists: [p1, p2],
          typeFilter: MediaType.tv,
        );
        expect(tvOnly.commonEntries, [const SharedMediaEntry(2, MediaType.tv)]);

        // Hide seen item (2:tv)
        final seenFiltered = ListIntersectionCalculator.multiIntersect(
          lists: [p1, p2],
          hideSeen: true,
          seenKeys: {(2, MediaType.tv)},
        );
        expect(seenFiltered.commonEntries, [const SharedMediaEntry(1, MediaType.movie)]);
      });
    });
  });
}
