import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No hard-coded color usage outside theme files', () {
    final repoRoot = Directory.current.path;
    final libDir = Directory('$repoRoot${Platform.pathSeparator}lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory not found');

    // Files/folders that are allowed to contain literal colors (theme implementations)
    final excludedPaths = <String>[
      'lib${Platform.pathSeparator}core${Platform.pathSeparator}theme',
    ];

    final colorHexReg = RegExp(r'Color\(\s*0x[0-9A-Fa-f]{6,8}\s*\)');
    final colorFromReg = RegExp(r'Color\.fromARGB\(|Color\.fromRGBO\(');
    // we'll scan for the literal `Colors.` token to avoid false-positives
    // inside identifiers like `appColors`
    const colorsToken = 'Colors.';

    final violations = <String>[];

    void checkFile(File file) {
      // compute a repo-relative path for clearer output
      final relative = file.path.replaceFirst(
        '$repoRoot${Platform.pathSeparator}',
        '',
      );

      for (final ex in excludedPaths) {
        if (relative.contains(ex)) return; // allowed location
      }

      final lines = file.readAsLinesSync();
      // allow only neutral color names and their shade variants (e.g. white54, grey[300])
      // This makes the test stricter: named semantic colors like `amber`, `green`,
      // `blue`, `red`, etc. must come from the theme (`context.appColors`).
      final allowedColorNames = <String>{'transparent'};

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        var hasViolation = false;

        if (colorHexReg.hasMatch(line) || colorFromReg.hasMatch(line)) {
          hasViolation = true;
        }

        // scan for occurrences of 'Colors.' but skip ones embedded inside other identifiers
        var scanStart = 0;
        while (true) {
          final idx = line.indexOf(colorsToken, scanStart);
          if (idx == -1) break;

          final isStandalone =
              idx == 0 || !RegExp(r'[A-Za-z0-9_]').hasMatch(line[idx - 1]);
          if (isStandalone) {
            final after = line.substring(idx + colorsToken.length);
            final mName = RegExp(r'^([A-Za-z0-9_]+)').firstMatch(after);
            if (mName != null) {
              final name = mName.group(1)!;
              if (name.startsWith('white') ||
                  name.startsWith('black') ||
                  name.startsWith('grey')) {
                // allowed shade/name variants
              } else if (allowedColorNames.contains(name)) {
                // allowed named colors (currently only 'transparent')
              } else {
                hasViolation = true;
                break;
              }
            }
          }

          scanStart = idx + colorsToken.length;
        }

        if (hasViolation) {
          violations.add('$relative:${i + 1}: ${line.trim()}');
        }
      }
    }

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        checkFile(entity);
      }
    }

    if (violations.isNotEmpty) {
      final msg = StringBuffer();
      msg.writeln('Hard-coded color usage detected in UI code.');
      msg.writeln('Allowed: theme palette files under `lib/core/theme`.');
      msg.writeln('\nViolations:');
      for (final v in violations) {
        msg.writeln('- $v');
      }
      msg.writeln(
        '\nFix by using `Theme.of(context).colorScheme` or `context.appColors` instead of literal colors.',
      );
      fail(msg.toString());
    }
  });
}
