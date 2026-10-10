import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockFlutterSecureStorage secure;
  late MockSharedPreferences prefs;

  const key = TmdbCredentialStore.secureStorageKey;
  const legacyKey = TmdbCredentialStore.legacyPrefsKey;

  setUp(() {
    secure = MockFlutterSecureStorage();
    prefs = MockSharedPreferences();
    when(() => prefs.remove(any())).thenAnswer((_) async => true);
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) => Future.value());
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) => Future.value());
  });

  group('TmdbCredentialStore.load', () {
    test('should read the credential from secure storage', () async {
      when(() => secure.read(key: key)).thenAnswer((_) async => 'secret');
      when(() => prefs.getString(legacyKey)).thenReturn(null);

      final store = await TmdbCredentialStore.load(
        secureStorage: secure,
        prefs: prefs,
      );

      expect(store.credential, 'secret');
      verifyNever(() => prefs.remove(any()));
    });

    test('should return empty string when nothing is stored', () async {
      when(() => secure.read(key: key)).thenAnswer((_) async => null);
      when(() => prefs.getString(legacyKey)).thenReturn(null);

      final store = await TmdbCredentialStore.load(
        secureStorage: secure,
        prefs: prefs,
      );

      expect(store.credential, '');
    });

    test('should migrate a legacy plain-text value and remove it', () async {
      when(() => secure.read(key: key)).thenAnswer((_) async => null);
      when(() => prefs.getString(legacyKey)).thenReturn(' legacy ');

      final store = await TmdbCredentialStore.load(
        secureStorage: secure,
        prefs: prefs,
      );

      expect(store.credential, 'legacy');
      verify(() => secure.write(key: key, value: 'legacy')).called(1);
      verify(() => prefs.remove(legacyKey)).called(1);
    });

    test('should keep the secure value and drop the legacy one', () async {
      when(() => secure.read(key: key)).thenAnswer((_) async => 'secure');
      when(() => prefs.getString(legacyKey)).thenReturn('legacy');

      final store = await TmdbCredentialStore.load(
        secureStorage: secure,
        prefs: prefs,
      );

      expect(store.credential, 'secure');
      verifyNever(
        () => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
      verify(() => prefs.remove(legacyKey)).called(1);
    });

    test('should keep the legacy value when the secure write fails', () async {
      when(() => secure.read(key: key)).thenAnswer((_) async => null);
      when(() => prefs.getString(legacyKey)).thenReturn('legacy');
      when(
        () => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(Exception('keystore unavailable'));

      final store = await TmdbCredentialStore.load(
        secureStorage: secure,
        prefs: prefs,
      );

      expect(store.credential, 'legacy');
      verifyNever(() => prefs.remove(any()));
    });

    test('should keep the legacy value when the secure read fails', () async {
      when(() => secure.read(key: key)).thenThrow(Exception('corrupted'));
      when(() => prefs.getString(legacyKey)).thenReturn('legacy');

      final store = await TmdbCredentialStore.load(
        secureStorage: secure,
        prefs: prefs,
      );

      expect(store.credential, 'legacy');
      verifyNever(
        () => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
      verifyNever(() => prefs.remove(any()));
    });
  });

  group('TmdbCredentialStore.save', () {
    late TmdbCredentialStore store;

    setUp(() async {
      when(() => secure.read(key: key)).thenAnswer((_) async => null);
      when(() => prefs.getString(legacyKey)).thenReturn(null);
      store = await TmdbCredentialStore.load(
        secureStorage: secure,
        prefs: prefs,
      );
    });

    test('should write the trimmed value to secure storage', () async {
      await store.save('  token  ');

      expect(store.credential, 'token');
      verify(() => secure.write(key: key, value: 'token')).called(1);
      verifyNever(() => prefs.setString(any(), any()));
    });

    test('should delete the entry when saving an empty value', () async {
      await store.save('   ');

      expect(store.credential, '');
      verify(() => secure.delete(key: key)).called(1);
    });
  });
}
