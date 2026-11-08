import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/app_version.dart';

void main() {
  test('appVersion matches the X.Y.Z of pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)(\+\d+)?\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'no version: line in pubspec.yaml');
    expect(appVersion, match!.group(1));
  });
}
