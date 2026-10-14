import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

List<int> _zip(Map<String, List<int>> files) {
  final archive = Archive();
  files.forEach((name, data) {
    archive.addFile(ArchiveFile(name, data.length, data));
  });
  return ZipEncoder().encode(archive);
}

List<int> _zipText(Map<String, String> files) =>
    _zip(files.map((k, v) => MapEntry(k, utf8.encode(v))));

String _entry(List<int> zipBytes, String name) =>
    utf8.decode(ZipDecoder().decodeBytes(zipBytes).findFile(name)!.content);

void main() {
  group('ExportEnvelope.fromZipBytes validation', () {
    test('should skip rows with invalid tmdbId and report them', () {
      final bytes = _zipText({
        'meta.csv': 'version,exportedAt,source\n1,2025-01-01T00:00:00Z,\n',
        'likes.csv':
            'tmdbId,type,title\n'
            '10,movie,Ok\n'
            ',movie,Missing\n'
            'abc,tv,NotANumber\n'
            '0,tv,Zero\n'
            '-3,tv,Negative\n',
      });

      final env = ExportEnvelope.fromZipBytes(bytes);

      expect(env.likes.map((l) => l.tmdbId), [10]);
      expect(env.warnings, hasLength(4));
      expect(env.warnings.first, 'likes.csv row 3: invalid tmdbId ""');
    });

    test('should skip rows with an unknown type', () {
      final bytes = _zipText({
        'seen.csv':
            'tmdbId,type,title,seenDate\n'
            '1,movie,A,2025-01-01T00:00:00Z\n'
            '2,book,B,2025-01-01T00:00:00Z\n'
            '3,,C,2025-01-01T00:00:00Z\n',
      });

      final env = ExportEnvelope.fromZipBytes(bytes);

      expect(env.seen.map((s) => s.tmdbId), [1]);
      expect(env.warnings, hasLength(2));
    });

    test('should skip seen rows without a valid seenDate', () {
      final bytes = _zipText({
        'seen.csv':
            'tmdbId,type,title,seenDate\n'
            '1,movie,A,not-a-date\n'
            '2,movie,B,\n',
      });

      final env = ExportEnvelope.fromZipBytes(bytes);

      expect(env.seen, isEmpty);
      expect(env.warnings, hasLength(2));
    });

    test('should skip list rows without a list name', () {
      final bytes = _zipText({
        'lists.csv':
            'listName,tmdbId,type,title,position\n'
            'watchlist,1,movie,A,0\n'
            ',2,movie,B,1\n',
      });

      final env = ExportEnvelope.fromZipBytes(bytes);

      expect(env.lists.keys, ['watchlist']);
      expect(env.lists['watchlist']!.single.id, 1);
      expect(env.warnings.single, contains('missing listName'));
    });

    test('should ignore blank lines', () {
      final bytes = _zipText({'likes.csv': 'tmdbId,type,title\n1,tv,A\n,,\n'});

      final env = ExportEnvelope.fromZipBytes(bytes);

      expect(env.likes, hasLength(1));
      expect(env.warnings, isEmpty);
    });

    test('should reject a version newer than supported', () {
      final bytes = _zipText({
        'meta.csv':
            'version,exportedAt,source\n'
            '${ExportEnvelope.currentVersion + 1},2025-01-01T00:00:00Z,\n',
        'likes.csv': 'tmdbId,type,title\n1,tv,A\n',
      });

      expect(
        () => ExportEnvelope.fromZipBytes(bytes),
        throwsA(isA<ParsingException>()),
      );
    });

    test('should reject a non-integer version', () {
      final bytes = _zipText({
        'meta.csv': 'version,exportedAt,source\nfoo,2025-01-01T00:00:00Z,\n',
      });

      expect(
        () => ExportEnvelope.fromZipBytes(bytes),
        throwsA(isA<ParsingException>()),
      );
    });

    test('should treat archives without meta.csv as version 1', () {
      final env = ExportEnvelope.fromZipBytes(
        _zipText({'likes.csv': 'tmdbId,type,title\n1,tv,A\n'}),
      );

      expect(env.version, 1);
      expect(env.likes, hasLength(1));
    });

    test('should wrap non-UTF-8 content in ParsingException', () {
      final bytes = _zip({
        'likes.csv': [0xff, 0xfe, 0xfd],
      });

      expect(
        () => ExportEnvelope.fromZipBytes(bytes),
        throwsA(isA<ParsingException>()),
      );
    });

    test('should wrap a corrupted archive in ParsingException', () {
      expect(
        () => ExportEnvelope.fromZipBytes(utf8.encode('not a zip at all')),
        throwsA(isA<ParsingException>()),
      );
    });

    test('should reject archives with too many entries', () {
      final files = {
        for (var i = 0; i <= ExportEnvelope.maxArchiveEntries; i++)
          'junk$i.txt': 'x',
      };

      expect(
        () => ExportEnvelope.fromZipBytes(_zipText(files)),
        throwsA(isA<ParsingException>()),
      );
    });

    test('should ignore unknown entries without decoding them', () {
      final bytes = _zip({
        'readme.bin': [0xff, 0xfe],
        'likes.csv': utf8.encode('tmdbId,type,title\n1,tv,A\n'),
      });

      expect(ExportEnvelope.fromZipBytes(bytes).likes, hasLength(1));
    });
  });

  group('ExportEnvelope dates', () {
    test('should export dates in UTC with a Z suffix', () {
      final local = DateTime(2025, 6, 1, 23, 30);
      final bytes = ExportEnvelope(
        version: 1,
        exportedAt: local,
        seen: [
          SeenItemModel(tmdbId: 1, type: 'movie', title: 'A', seenDate: local),
        ],
      ).toZipBytes();

      final seenCsv = _entry(bytes, 'seen.csv');
      expect(seenCsv, contains(local.toUtc().toIso8601String()));
      expect(_entry(bytes, 'meta.csv'), contains('Z'));
    });

    test('should round-trip a local seenDate to the same instant', () {
      final local = DateTime(2025, 6, 1, 23, 30, 15);
      final env = ExportEnvelope.fromZipBytes(
        ExportEnvelope(
          version: 1,
          exportedAt: local,
          seen: [
            SeenItemModel(
              tmdbId: 1,
              type: 'movie',
              title: 'A',
              seenDate: local,
            ),
          ],
        ).toZipBytes(),
      );

      expect(env.seen.single.seenDate.isAtSameMomentAs(local), isTrue);
    });

    test('should read legacy dates without offset as local time', () {
      final env = ExportEnvelope.fromZipBytes(
        _zipText({
          'seen.csv':
              'tmdbId,type,title,seenDate\n1,movie,A,2024-05-01T20:00:00.000\n',
        }),
      );

      expect(env.seen.single.seenDate, DateTime(2024, 5, 1, 20));
    });
  });

  group('ExportEnvelope formula injection', () {
    test('should prefix formula-like titles with a quote on export', () {
      final bytes = ExportEnvelope(
        version: 1,
        exportedAt: DateTime.utc(2025),
        likes: [LikedItem(tmdbId: 1, type: 'movie', title: '=HYPERLINK("x")')],
      ).toZipBytes();

      expect(_entry(bytes, 'likes.csv'), contains("'=HYPERLINK"));
    });

    test('should round-trip free-text cells unchanged', () {
      const titles = [
        '=1+1',
        '+33 6',
        '-Minus',
        '@user',
        "'=already quoted",
        "''@double",
        "'Salem's Lot",
        'Plain',
      ];
      final env = ExportEnvelope.fromZipBytes(
        ExportEnvelope(
          version: 1,
          exportedAt: DateTime.utc(2025),
          likes: [
            for (var i = 0; i < titles.length; i++)
              LikedItem(tmdbId: i + 1, type: 'movie', title: titles[i]),
          ],
          lists: {
            '=list': [
              MediaListItem(
                id: 1,
                type: 'tv',
                title: '-t',
                listName: '=list',
                position: 0,
              ),
            ],
          },
        ).toZipBytes(),
      );

      expect(env.likes.map((l) => l.title), titles);
      expect(env.lists.keys, ['=list']);
      expect(env.lists['=list']!.single.title, '-t');
    });

    test('should keep legacy titles starting with a quote', () {
      final env = ExportEnvelope.fromZipBytes(
        _zipText({'likes.csv': "tmdbId,type,title\n1,movie,'Salem's Lot\n"}),
      );

      expect(env.likes.single.title, "'Salem's Lot");
    });
  });
}
