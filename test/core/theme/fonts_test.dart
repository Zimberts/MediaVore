import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_typography.dart';
import 'package:mediavore/core/theme/font_licenses.dart';

/// `family -> {weight -> asset}` declared under `flutter: fonts:`.
Map<String, Map<int, String>> _declaredFonts(String pubspec) {
  final fonts = <String, Map<int, String>>{};
  String? family;
  String? asset;
  for (final line in pubspec.split('\n')) {
    final familyMatch = RegExp(r'^\s*- family:\s*(.+)$').firstMatch(line);
    final assetMatch = RegExp(r'^\s*- asset:\s*(.+)$').firstMatch(line);
    final weightMatch = RegExp(r'^\s*weight:\s*(\d+)$').firstMatch(line);
    if (familyMatch != null) {
      family = familyMatch.group(1)!.trim();
      fonts[family] = {};
    } else if (assetMatch != null) {
      asset = assetMatch.group(1)!.trim();
    } else if (weightMatch != null && family != null && asset != null) {
      fonts[family]![int.parse(weightMatch.group(1)!)] = asset;
    }
  }
  return fonts;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pubspec = File('pubspec.yaml').readAsStringSync();
  final fonts = _declaredFonts(pubspec);

  group('Bundled fonts', () {
    test('should declare Bricolage Grotesque 500/700 and Inter 400-700', () {
      expect(fonts.keys, containsAll([AppFonts.heading, AppFonts.body]));
      expect(fonts[AppFonts.heading]!.keys, unorderedEquals([500, 700]));
      expect(fonts[AppFonts.body]!.keys, unorderedEquals([400, 500, 600, 700]));
    });

    test('should ship every declared file as a static TrueType font', () {
      for (final family in fonts.values) {
        for (final asset in family.values) {
          final file = File(asset);
          expect(file.existsSync(), isTrue, reason: asset);
          expect(asset, startsWith('assets/fonts/'));
          final bytes = file.readAsBytesSync();
          // TrueType outlines: sfnt version 0x00010000.
          expect(bytes.sublist(0, 4), [0, 1, 0, 0], reason: asset);
          // A variable font would carry an `fvar` table.
          final tableCount = (bytes[4] << 8) | bytes[5];
          final tags = [
            for (var i = 0; i < tableCount; i++)
              String.fromCharCodes(bytes.sublist(12 + 16 * i, 16 + 16 * i)),
          ];
          expect(tags, isNot(contains('fvar')), reason: asset);
        }
      }
    });

    test('should load every declared file offline', () async {
      for (final entry in fonts.entries) {
        final loader = FontLoader(entry.key);
        for (final asset in entry.value.values) {
          final bytes = File(asset).readAsBytesSync();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
        await loader.load();
      }
    });

    test('should ship the OFL license next to each family', () {
      for (final asset in fontLicenseAssets.values) {
        final text = File(asset).readAsStringSync();
        expect(text, contains('SIL Open Font License'), reason: asset);
        expect(pubspec, contains('- $asset'));
      }
    });

    test('should never fetch fonts from the network', () {
      expect(pubspec, isNot(contains('google_fonts')));
      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in sources) {
        final content = file.readAsStringSync();
        expect(content, isNot(contains('fonts.googleapis.com')));
        expect(content, isNot(contains('fonts.gstatic.com')));
        expect(content, isNot(contains('google_fonts')));
      }
    });
  });

  group('registerFontLicenses', () {
    test('should list the license of both families', () async {
      registerFontLicenses();

      final entries = await LicenseRegistry.licenses
          .where((entry) => entry.packages.any(fontLicenseAssets.keys.contains))
          .toList();

      expect(entries.expand((entry) => entry.packages), {
        AppFonts.heading,
        AppFonts.body,
      });
      for (final entry in entries) {
        final text = entry.paragraphs.map((p) => p.text).join('\n');
        expect(text, contains('SIL Open Font License'));
      }
    });
  });
}
