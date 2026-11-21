// Checks line coverage from `coverage/lcov.info` against a minimum.
//
// Usage: dart run tool/check_coverage.dart [lcov.info] [threshold-file]
//
// Generated code (`*.g.dart`, `*.config.dart`, `lib/l10n/generated/`) is
// left out. Prints a per-area table (Markdown, also appended to
// $GITHUB_STEP_SUMMARY in CI) and exits with 1 when the total is below the
// minimum stored in tool/coverage_threshold.txt. Raise that minimum when
// coverage goes up; never lower it to make a PR pass.
import 'dart:io';

final _generated = RegExp(r'(\.g\.dart|\.config\.dart)$|^lib/l10n/generated/');

void main(List<String> args) {
  final lcovPath = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final thresholdPath = args.length > 1
      ? args[1]
      : 'tool/coverage_threshold.txt';

  final lcov = File(lcovPath);
  if (!lcov.existsSync()) {
    stderr.writeln('No $lcovPath: run `flutter test --coverage` first.');
    exit(2);
  }
  final minimum = double.parse(File(thresholdPath).readAsStringSync().trim());

  final found = <String, int>{};
  final hit = <String, int>{};
  String? file;
  for (final line in lcov.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).replaceAll(r'\', '/');
      file = _generated.hasMatch(path) ? null : _area(path);
    } else if (file != null && line.startsWith('LF:')) {
      found[file] = (found[file] ?? 0) + int.parse(line.substring(3));
    } else if (file != null && line.startsWith('LH:')) {
      hit[file] = (hit[file] ?? 0) + int.parse(line.substring(3));
    }
  }

  final totalFound = found.values.fold(0, (a, b) => a + b);
  final totalHit = hit.values.fold(0, (a, b) => a + b);
  if (totalFound == 0) {
    stderr.writeln('No measurable lines in $lcovPath.');
    exit(2);
  }
  final total = 100 * totalHit / totalFound;

  final areas = found.keys.toList()
    ..sort(
      (a, b) => _pct(hit[a], found[a]!).compareTo(_pct(hit[b], found[b]!)),
    );
  final report = StringBuffer()
    ..writeln(
      '### Line coverage: ${total.toStringAsFixed(1)} % '
      '(minimum ${minimum.toStringAsFixed(1)} %)',
    )
    ..writeln()
    ..writeln('| Area | Lines | Covered |')
    ..writeln('| --- | ---: | ---: |');
  for (final area in areas) {
    report.writeln(
      '| `$area` | ${found[area]} | '
      '${_pct(hit[area], found[area]!).toStringAsFixed(1)} % |',
    );
  }
  report.writeln(
    '| **Total** | $totalFound | '
    '**${total.toStringAsFixed(1)} %** |',
  );

  stdout.write(report);
  final summary = Platform.environment['GITHUB_STEP_SUMMARY'];
  if (summary != null && summary.isNotEmpty) {
    File(summary).writeAsStringSync('$report\n', mode: FileMode.append);
  }

  // Compare rounded to 0.1 so the printed figures match the decision.
  if ((total * 10).floor() < (minimum * 10).round()) {
    stderr.writeln(
      'Coverage ${total.toStringAsFixed(1)} % is below the minimum '
      '${minimum.toStringAsFixed(1)} % (tool/coverage_threshold.txt).',
    );
    exit(1);
  }
}

/// `lib/features/<feature>`, `lib/<dir>` or the file itself (`lib/main.dart`).
String _area(String path) {
  final parts = path.split('/');
  if (parts.length > 3 && parts[1] == 'features') {
    return parts.take(3).join('/');
  }
  return parts.length > 2 ? parts.take(2).join('/') : path;
}

double _pct(int? hit, int found) => 100 * (hit ?? 0) / found;
