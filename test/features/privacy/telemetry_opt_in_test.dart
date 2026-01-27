import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';

// Tests here are lightweight assertions that exercise the privacy-related
// surface area that currently exists in the codebase. The app's telemetry
// feature is not implemented; these tests assert defaults and exported data
// shape to guard against accidental inclusion of PII.

void main() {
  group('Privacy / Telemetry (basic)', () {
    late MockSharedPreferences mockPrefs;
    late MockMediaRepository mockRepository;

    setUpAll(() {
      registerFallbackValue(FakeMediaItem());
      registerFallbackValue(FakeSeenItem());
    });

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockRepository = MockMediaRepository();

      // Default prefs responses
      when(() => mockPrefs.getInt(any())).thenReturn(null);
      when(() => mockPrefs.getDouble(any())).thenReturn(null);
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      // Basic repository stubs used by SearchProvider._init()
      when(
        () => mockRepository.getAllListNames(),
      ).thenAnswer((_) async => ['watchlist']);
      when(
        () => mockRepository.getListEntries(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
      when(
        () => mockRepository.getWatchlistEntries(),
      ).thenAnswer((_) async => []);
      when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
      when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
      when(() => mockRepository.createList(any())).thenAnswer((_) async {});
      when(
        () => mockRepository.addToList(any(), any()),
      ).thenAnswer((_) async {});
    });

    test('telemetry is not present in settings by default', () async {
      // SettingsProvider currently has no telemetry key. Ensure no code
      // reads or writes a 'telemetry' boolean during construction.
      final settings = SettingsProvider(mockPrefs);

      // The provider loads settings on construct; verify it didn't access a
      // telemetry key (no telemetry implementation yet).
      verifyNever(() => mockPrefs.getBool('telemetry'));
      expect(settings.displayMode, isNotNull);
    });

    test('exported seen data does not include PII keys', () async {
      // Stub repository to return a typical exported record set.
      final sample = [
        {
          'tmdbId': 123,
          'type': 'movie',
          'title': 'Sample Movie',
          'posterPath': '/x.jpg',
          'seenDate': DateTime.now().toIso8601String(),
          'seasonNumber': null,
          'episodeNumber': null,
          'runtime': 120,
          'genres': ['Drama'],
        },
      ];

      when(
        () => mockRepository.exportSeenData(),
      ).thenAnswer((_) async => sample);

      final provider = SearchProvider(mockRepository);
      final exported = await provider.exportSeenData();

      // Ensure exported data keys do not contain obvious PII fields.
      for (final row in exported) {
        expect(row.containsKey('email'), isFalse);
        expect(row.containsKey('userId'), isFalse);
        expect(row.containsKey('deviceId'), isFalse);
      }
    });
  });
}
