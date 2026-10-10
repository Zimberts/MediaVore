import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/bounded_concurrency.dart';

void main() {
  group('mapWithConcurrency', () {
    test('should preserve order and never exceed the limit', () async {
      var inFlight = 0;
      var maxInFlight = 0;
      final items = List.generate(20, (i) => i);

      final results = await mapWithConcurrency(items, 4, (i) async {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        // Finish in reverse-ish order to check output ordering.
        await Future<void>.delayed(Duration(milliseconds: 20 - i));
        inFlight--;
        return i * 2;
      });

      expect(results, items.map((i) => i * 2).toList());
      expect(maxInFlight, 4);
    });

    test('should handle an empty list', () async {
      expect(await mapWithConcurrency<int, int>([], 4, (i) async => i), []);
    });

    test('should reject a non-positive limit', () {
      expect(
        () => mapWithConcurrency<int, int>([1], 0, (i) async => i),
        throwsArgumentError,
      );
    });
  });
}
