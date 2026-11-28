import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'embedded_fixtures.dart';
import 'fixture_reader.dart';

void main() {
  group('fixture_reader', () {
    tearDown(clearRegisteredTestFixtures);

    test('should keep embedded text fixtures in sync with test/fixtures', () {
      final diskFiles = Directory('test/fixtures')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map(
            (f) =>
                f.path.replaceFirst('test/fixtures/', '').replaceAll('\\', '/'),
          )
          .toSet();

      expect(embeddedTextFixtures.keys.toSet(), diskFiles);
      for (final entry in embeddedTextFixtures.entries) {
        expect(
          entry.value,
          File('test/fixtures/${entry.key}').readAsStringSync(),
          reason: '${entry.key} differs from disk',
        );
      }
    });

    test('should keep embedded binary fixtures in sync with test/fixtures', () {
      for (final entry in embeddedBinaryFixturesBase64.entries) {
        expect(
          base64Decode(entry.value),
          File('test/fixtures/${entry.key}').readAsBytesSync(),
          reason: '${entry.key} differs from disk',
        );
      }
    });

    test('should prefer registered fixtures over disk when present', () {
      registerTestFixtures(
        text: {'tmdb/movie.json': '{"registered":true}'},
        binaryBase64: {
          'sample.bin': base64Encode([1, 2, 3]),
        },
      );

      expect(fixture('tmdb/movie.json'), '{"registered":true}');
      expect(fixtureBytes('sample.bin'), [1, 2, 3]);
    });
  });
}
