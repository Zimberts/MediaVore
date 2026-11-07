import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockPrefs;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  final l10n = fallbackLocalizations;

  setUp(() {
    mockRepository = MockMediaRepository();
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockPrefs, FakeTmdbCredentialStore());
  });

  /// Pumps a host page that pushes [page] and records what it pops.
  Future<List<bool?>> pumpPage(WidgetTester tester, Widget page) async {
    final results = <bool?>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => results.add(
                  await Navigator.of(
                    context,
                  ).push<bool>(MaterialPageRoute(builder: (_) => page)),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  Future<void> submit(WidgetTester tester, String key) async {
    await tester.enterText(find.byKey(const Key('tmdb_credential_field')), key);
    await tester.pump();
    await tester.tap(find.byKey(const Key('tmdb_credential_verify')));
    await tester.pumpAndSettle();
  }

  group('TmdbCredentialPage', () {
    testWidgets('should save a key TMDB accepts and pop true', (tester) async {
      when(
        () => mockRepository.validateTmdbCredential(any()),
      ).thenAnswer((_) async {});
      final results = await pumpPage(
        tester,
        const TmdbCredentialPage(onboarding: true),
      );

      await submit(tester, '  good_key  ');

      verify(() => mockRepository.validateTmdbCredential('good_key')).called(1);
      expect(settingsProvider.tmdbApiKey, 'good_key');
      expect(results, [true]);
      expect(find.text(l10n.tmdbCredentialSaved), findsOneWidget);
    });

    testWidgets('should reject a key TMDB refuses, without saving it', (
      tester,
    ) async {
      when(
        () => mockRepository.validateTmdbCredential(any()),
      ).thenThrow(const ServerException('unauthorized', 401));
      final results = await pumpPage(
        tester,
        const TmdbCredentialPage(onboarding: true),
      );

      await submit(tester, 'bad_key');

      expect(find.text(l10n.tmdbCredentialInvalid), findsOneWidget);
      expect(
        find.byKey(const Key('tmdb_credential_save_anyway')),
        findsNothing,
      );
      expect(settingsProvider.tmdbApiKey, isEmpty);
      expect(results, isEmpty);
    });

    testWidgets('should offer to save unverified when TMDB is unreachable', (
      tester,
    ) async {
      when(
        () => mockRepository.validateTmdbCredential(any()),
      ).thenThrow(const NetworkException('offline'));
      final results = await pumpPage(
        tester,
        const TmdbCredentialPage(onboarding: true),
      );

      await submit(tester, 'some_key');

      expect(
        find.text(
          l10n.tmdbCredentialCheckFailed(
            searchErrorMessage(SearchErrorType.offline, l10n),
          ),
        ),
        findsOneWidget,
      );
      expect(settingsProvider.tmdbApiKey, isEmpty);

      await tester.tap(find.byKey(const Key('tmdb_credential_save_anyway')));
      await tester.pumpAndSettle();

      expect(settingsProvider.tmdbApiKey, 'some_key');
      expect(results, [true]);
    });

    testWidgets('should clear the error once the key is edited', (
      tester,
    ) async {
      when(
        () => mockRepository.validateTmdbCredential(any()),
      ).thenThrow(const ServerException('unauthorized', 401));
      await pumpPage(tester, const TmdbCredentialPage(onboarding: true));

      await submit(tester, 'bad_key');
      expect(find.text(l10n.tmdbCredentialInvalid), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('tmdb_credential_field')),
        'bad_key2',
      );
      await tester.pump();
      expect(find.text(l10n.tmdbCredentialInvalid), findsNothing);
    });

    testWidgets('should disable verification while the field is empty', (
      tester,
    ) async {
      await pumpPage(tester, const TmdbCredentialPage(onboarding: true));

      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('tmdb_credential_verify')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should open the TMDB API page', (tester) async {
      final opened = <Uri>[];
      await pumpPage(
        tester,
        TmdbCredentialPage(
          onboarding: true,
          openUrl: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      );

      await tester.tap(find.byKey(const Key('tmdb_open_api_page')));
      await tester.pump();

      expect(opened, [tmdbApiSettingsUri]);
    });

    testWidgets('should pop false when skipped during onboarding', (
      tester,
    ) async {
      final results = await pumpPage(
        tester,
        const TmdbCredentialPage(onboarding: true),
      );

      await tester.tap(find.byKey(const Key('tmdb_credential_skip')));
      await tester.pumpAndSettle();

      expect(results, [false]);
      verifyNever(() => mockRepository.validateTmdbCredential(any()));
    });

    testWidgets('should remove a stored key from Settings', (tester) async {
      await settingsProvider.setTmdbApiKey('old_key');
      final results = await pumpPage(tester, const TmdbCredentialPage());

      expect(find.byKey(const Key('tmdb_credential_skip')), findsNothing);
      await tester.tap(find.byKey(const Key('tmdb_credential_remove')));
      await tester.pumpAndSettle();

      expect(settingsProvider.tmdbApiKey, isEmpty);
      expect(results, [true]);
    });
  });
}
