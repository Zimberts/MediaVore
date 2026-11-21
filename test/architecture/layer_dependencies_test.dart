import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Layer rules of `lib/features/<feature>/{data,domain,presentation}` (see
/// CLAUDE.md, Architecture): `domain` depends on neither `data` nor
/// `presentation`, and `data` does not depend on `presentation`.
///
/// [_knownViolations] lists the imports that predate this test. Remove an
/// entry once it is fixed; never add one to make a new import pass.
const _knownViolations = {
  'lib/features/search/domain/repositories/media_repository.dart -> '
      'features/media_details/data/models/swipe_decision_model.dart',
};

final _import = RegExp(
  r'''^import 'package:mediavore/(features/[a-z_]+/(data|domain|presentation)/[^']+)';''',
  multiLine: true,
);

/// Layers a file in [layer] must not import.
const _forbidden = {
  'domain': {'data', 'presentation'},
  'data': {'presentation'},
};

void main() {
  group('layer dependencies', () {
    test('should keep domain and data independent of outer layers', () {
      final violations = <String>[];
      final dartFiles = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final path = file.path.replaceAll(r'\', '/');
        final layer = RegExp(
          r'^lib/features/[a-z_]+/(data|domain|presentation)/',
        ).firstMatch(path)?.group(1);
        final forbidden = _forbidden[layer];
        if (forbidden == null) continue;

        for (final match in _import.allMatches(file.readAsStringSync())) {
          if (!forbidden.contains(match.group(2))) continue;
          final violation = '$path -> ${match.group(1)}';
          if (!_knownViolations.contains(violation)) violations.add(violation);
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('should not keep fixed violations in the allowlist', () {
      for (final violation in _knownViolations) {
        final parts = violation.split(' -> ');
        final source = File(parts[0]);
        expect(
          source.existsSync() &&
              source.readAsStringSync().contains(
                "import 'package:mediavore/${parts[1]}';",
              ),
          isTrue,
          reason: '$violation is fixed: remove it from _knownViolations.',
        );
      }
    });
  });
}
