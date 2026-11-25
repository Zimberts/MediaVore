import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

/// Archive holding [files] (name to CSV text).
List<int> _zip(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    final bytes = utf8.encode(value);
    archive.addFile(ArchiveFile(key, bytes.length, bytes));
  }
  return ZipEncoder().encode(archive);
}

void main() {
  group('ExportEnvelope quick add opt-outs', () {
    test('should restore every opt-out when an envelope round-trips', () {
      final original = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025),
        optOuts: [
          QuickAddOptOutModel(
            tmdbId: 100,
            seasonNumber: 2,
            episodeNumber: 5,
            optedOutAt: DateTime.utc(2025, 1, 15, 8),
          ),
          QuickAddOptOutModel(tmdbId: 200, optedOutAt: DateTime.utc(2024, 3)),
        ],
      );

      final parsed = ExportEnvelope.fromZipBytes(original.toZipBytes());

      expect(
        [
          for (final o in parsed.optOuts)
            (o.tmdbId, o.seasonNumber, o.episodeNumber, o.optedOutAt),
        ],
        [
          (100, 2, 5, DateTime.utc(2025, 1, 15, 8)),
          (200, null, null, DateTime.utc(2024, 3)),
        ],
      );
      expect(parsed.warnings, isEmpty);
    });

    test('should write no optouts.csv when there is no opt-out', () {
      final bytes = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025),
        seen: [
          SeenItemModel(
            tmdbId: 1,
            type: 'movie',
            title: 'A',
            seenDate: DateTime.utc(2025),
          ),
        ],
      ).toZipBytes();

      final names = ZipDecoder().decodeBytes(bytes).map((f) => f.name);
      expect(names, isNot(contains('optouts.csv')));
      expect(ExportEnvelope.fromZipBytes(bytes).optOuts, isEmpty);
    });

    test('should date an opt-out with the export when optedOutAt is '
        'missing, and skip a row with an invalid id or episode', () {
      final parsed = ExportEnvelope.fromZipBytes(
        _zip({
          'meta.csv':
              'version,exportedAt,source\r\n1,2025-06-01T10:00:00.000Z,\r\n',
          'optouts.csv':
              'tmdbId,seasonNumber,episodeNumber,optedOutAt\r\n'
              '300,1,2,\r\n'
              'abc,1,2,2025-01-01T00:00:00.000Z\r\n'
              '400,one,2,2025-01-01T00:00:00.000Z\r\n',
        }),
      );

      expect(parsed.optOuts, hasLength(1));
      expect(parsed.optOuts.single.tmdbId, 300);
      expect(parsed.optOuts.single.optedOutAt, DateTime.utc(2025, 6, 1, 10));
      expect(parsed.warnings, [
        'optouts.csv row 3: invalid tmdbId "abc"',
        'optouts.csv row 4: invalid seasonNumber "one"',
      ]);
    });
  });
}
