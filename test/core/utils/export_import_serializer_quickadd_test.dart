import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';

void main() {
  group('ExportEnvelope QuickAdd serialization', () {
    test('exports quickadd.csv with correct columns', () {
      final envelope = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025, 1, 1),
        quickAdd: [
          QuickAddItemModel(
            tmdbId: 100,
            type: 'tv',
            seasonNumber: 2,
            episodeNumber: 5,
            insertedAt: DateTime.utc(2025, 1, 15),
            airDate: DateTime.utc(2025, 2, 1),
            title: 'Breaking Bad',
            posterPath: '/poster.jpg',
          ),
          QuickAddItemModel(
            tmdbId: 200,
            type: 'movie',
            seasonNumber: null,
            episodeNumber: null,
            insertedAt: DateTime.utc(2025, 1, 20),
            airDate: null,
            title: 'Inception',
            posterPath: null,
          ),
        ],
      );

      final zipBytes = envelope.toZipBytes();
      expect(zipBytes.isNotEmpty, true);
    });

    test('parses quickadd.csv from import with all fields', () {
      final original = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025, 1, 1),
        quickAdd: [
          QuickAddItemModel(
            tmdbId: 100,
            type: 'tv',
            seasonNumber: 2,
            episodeNumber: 5,
            insertedAt: DateTime.utc(2025, 1, 15),
            airDate: DateTime.utc(2025, 2, 1),
            title: 'Breaking Bad',
            posterPath: '/poster.jpg',
          ),
        ],
      );

      final zipBytes = original.toZipBytes();
      final parsed = ExportEnvelope.fromZipBytes(zipBytes);

      expect(parsed.quickAdd.length, 1);
      final qa = parsed.quickAdd[0];
      expect(qa.tmdbId, 100);
      expect(qa.type, 'tv');
      expect(qa.seasonNumber, 2);
      expect(qa.episodeNumber, 5);
      expect(qa.title, 'Breaking Bad');
      expect(qa.posterPath, '/poster.jpg');
      expect(qa.airDate?.year, 2025);
    });

    test('parses quickadd.csv with nullable fields', () {
      final original = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025, 1, 1),
        quickAdd: [
          QuickAddItemModel(
            tmdbId: 200,
            type: 'movie',
            seasonNumber: null,
            episodeNumber: null,
            insertedAt: DateTime.utc(2025, 1, 20),
            airDate: null,
            title: null,
            posterPath: null,
          ),
        ],
      );

      final zipBytes = original.toZipBytes();
      final parsed = ExportEnvelope.fromZipBytes(zipBytes);

      expect(parsed.quickAdd.length, 1);
      final qa = parsed.quickAdd[0];
      expect(qa.seasonNumber, null);
      expect(qa.episodeNumber, null);
      expect(qa.title, null);
      expect(qa.posterPath, null);
    });

    test('handles empty quickadd gracefully', () {
      final envelope = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025, 1, 1),
        quickAdd: [],
      );

      final zipBytes = envelope.toZipBytes();
      final parsed = ExportEnvelope.fromZipBytes(zipBytes);

      expect(parsed.quickAdd.length, 0);
    });

    test('round-trips multiple quickadd items correctly', () {
      final items = [
        QuickAddItemModel(
          tmdbId: 1,
          type: 'tv',
          seasonNumber: 1,
          episodeNumber: 1,
          insertedAt: DateTime.utc(2025, 1, 1),
          airDate: DateTime.utc(2025, 1, 8),
          title: 'Show A',
          posterPath: '/a.jpg',
        ),
        QuickAddItemModel(
          tmdbId: 2,
          type: 'tv',
          seasonNumber: 3,
          episodeNumber: 10,
          insertedAt: DateTime.utc(2025, 1, 2),
          airDate: DateTime.utc(2025, 1, 15),
          title: 'Show B',
          posterPath: '/b.jpg',
        ),
      ];

      final original = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025, 1, 1),
        quickAdd: items,
      );

      final zipBytes = original.toZipBytes();
      final parsed = ExportEnvelope.fromZipBytes(zipBytes);

      expect(parsed.quickAdd.length, 2);
      expect(parsed.quickAdd[0].tmdbId, 1);
      expect(parsed.quickAdd[0].seasonNumber, 1);
      expect(parsed.quickAdd[1].tmdbId, 2);
      expect(parsed.quickAdd[1].episodeNumber, 10);
    });

    test('preserves timestamps during round-trip', () {
      final insertTime = DateTime.utc(2025, 3, 15, 14, 30, 45);
      final airTime = DateTime.utc(2025, 3, 22, 20, 0, 0);

      final original = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025, 1, 1),
        quickAdd: [
          QuickAddItemModel(
            tmdbId: 100,
            type: 'tv',
            seasonNumber: 1,
            episodeNumber: 1,
            insertedAt: insertTime,
            airDate: airTime,
            title: 'Test',
            posterPath: null,
          ),
        ],
      );

      final zipBytes = original.toZipBytes();
      final parsed = ExportEnvelope.fromZipBytes(zipBytes);

      expect(parsed.quickAdd[0].insertedAt, insertTime);
      expect(parsed.quickAdd[0].airDate, airTime);
    });
  });
}
