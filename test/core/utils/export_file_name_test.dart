import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/export_file_name.dart';

void main() {
  group('exportFileName', () {
    test('should format local date-time as yyyy-MM-dd_HH-mm-ss', () {
      expect(
        exportFileName(DateTime(2026, 10, 25, 13, 36, 54)),
        'mediavore_export_2026-10-25_13-36-54.mdv',
      );
    });

    test(
      'should zero-pad single-digit month, day, hour, minute and second',
      () {
        expect(
          exportFileName(DateTime(2026, 1, 5, 7, 8, 9)),
          'mediavore_export_2026-01-05_07-08-09.mdv',
        );
      },
    );

    test('should render midnight as 00-00-00', () {
      expect(
        exportFileName(DateTime(2026, 12, 31)),
        'mediavore_export_2026-12-31_00-00-00.mdv',
      );
    });

    test('should ignore milliseconds', () {
      expect(
        exportFileName(DateTime(2026, 3, 4, 5, 6, 7, 999)),
        'mediavore_export_2026-03-04_05-06-07.mdv',
      );
    });

    test('should use local time when given a UTC date-time', () {
      final utc = DateTime.utc(2026, 6, 15, 23, 59, 59);
      expect(exportFileName(utc), exportFileName(utc.toLocal()));
    });

    test('should sort chronologically by name', () {
      final dates = [
        DateTime(2026, 10, 2, 9),
        DateTime(2025, 12, 31, 23, 59, 59),
        DateTime(2026, 10, 2, 10),
        DateTime(2026, 9, 30),
      ];
      final byName = dates.map(exportFileName).toList()..sort();
      final byDate = ([...dates]..sort()).map(exportFileName).toList();
      expect(byName, byDate);
    });

    test('should not contain characters invalid in file names', () {
      expect(
        exportFileName(DateTime(2026, 10, 25, 13, 36, 54)),
        isNot(matches(RegExp(r'[:\\/*?"<>| ]'))),
      );
    });
  });
}
