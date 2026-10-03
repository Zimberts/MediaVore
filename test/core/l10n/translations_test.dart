import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/app_language.dart';

/// Guards the "add a language = ARB file + AppLanguage entry" contract.
void main() {
  Map<String, dynamic> readArb(String code) =>
      jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
          as Map<String, dynamic>;

  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  group('translations', () {
    test('should have one ARB file per supported language', () {
      final arbCodes = Directory('lib/l10n')
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.startsWith('app_') && name.endsWith('.arb'))
          .map((name) => name.substring(4, name.length - 4))
          .toSet();

      expect(arbCodes, supportedAppLanguages.map((l) => l.code).toSet());
    });

    test('should translate every template key in every language', () {
      final template = messageKeys(readArb(fallbackAppLanguage.code));
      for (final language in supportedAppLanguages) {
        final keys = messageKeys(readArb(language.code));
        expect(
          template.difference(keys),
          isEmpty,
          reason: 'missing keys in app_${language.code}.arb',
        );
        expect(
          keys.difference(template),
          isEmpty,
          reason: 'keys in app_${language.code}.arb not in the template',
        );
      }
    });

    test('should translate every achievement in every language', () {
      final definitions =
          jsonDecode(
                File('assets/achievements/definitions.json').readAsStringSync(),
              )
              as List<dynamic>;
      for (final language in supportedAppLanguages) {
        if (language == fallbackAppLanguage) continue;
        for (final def in definitions.cast<Map<String, dynamic>>()) {
          final translation =
              (def['translations'] as Map?)?[language.code] as Map?;
          expect(
            translation?['title'],
            isA<String>(),
            reason: '${def['id']} has no ${language.code} title',
          );
          expect(
            translation?['description'],
            isA<String>(),
            reason: '${def['id']} has no ${language.code} description',
          );
        }
      }
    });
  });
}
