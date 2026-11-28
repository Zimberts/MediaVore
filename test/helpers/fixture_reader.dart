import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

final Map<String, String> _textFixtures = {};
final Map<String, Uint8List> _binaryFixtures = {};

/// Registers in-memory fixtures for environments where `test/fixtures/` is not
/// on the local filesystem (for example, `integration_test` on a device).
void registerTestFixtures({
  Map<String, String> text = const {},
  Map<String, String> binaryBase64 = const {},
}) {
  _textFixtures.addAll(text);
  for (final entry in binaryBase64.entries) {
    _binaryFixtures[entry.key] = base64Decode(entry.value);
  }
}

/// Clears any registered in-memory fixtures (for unit tests).
void clearRegisteredTestFixtures() {
  _textFixtures.clear();
  _binaryFixtures.clear();
}

String fixture(String name) =>
    _textFixtures[name] ?? File('test/fixtures/$name').readAsStringSync();

Uint8List fixtureBytes(String name) =>
    _binaryFixtures[name] ?? File('test/fixtures/$name').readAsBytesSync();
