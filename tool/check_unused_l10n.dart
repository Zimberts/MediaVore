// Lists ARB keys that no Dart file under lib/ reads.
//
// Usage: dart run tool/check_unused_l10n.dart
//
// A key counts as used when `.<key>` appears in a Dart file outside
// lib/l10n/generated/ (e.g. `context.l10n.homeTitle`, `l10n.homeTitle`).
// Exits with 1 and prints the unused keys when there are any, so stale
// strings are removed with the code that used them.
import 'dart:convert';
import 'dart:io';

void main() {
  final template = File('lib/l10n/app_en.arb');
  final keys = (jsonDecode(template.readAsStringSync()) as Map<String, dynamic>)
      .keys
      .where((key) => !key.startsWith('@'))
      .toList();

  final used = <String>{};
  final member = RegExp(r'\.([A-Za-z_][A-Za-z0-9_]*)');
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) =>
            f.path.endsWith('.dart') &&
            !f.path.replaceAll(r'\', '/').startsWith('lib/l10n/generated/'),
      );
  for (final file in sources) {
    for (final match in member.allMatches(file.readAsStringSync())) {
      used.add(match.group(1)!);
    }
  }

  final unused = keys.where((key) => !used.contains(key)).toList()..sort();
  if (unused.isEmpty) {
    stdout.writeln('All ${keys.length} ARB keys are used.');
    return;
  }
  stderr
    ..writeln('${unused.length} of ${keys.length} ARB keys are never read:')
    ..writeln(unused.map((key) => '  $key').join('\n'))
    ..writeln('Remove them from every lib/l10n/app_*.arb file.');
  exit(1);
}
