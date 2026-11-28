// Journey #463: first launch without a TMDB key, then the key's life cycle
// (rejected, saved, kept across a relaunch, removed).
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mediavore/features/profile/presentation/pages/profile_page.dart';
import 'package:mediavore/features/search/presentation/pages/main_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_tmdb.dart';
import '../harness.dart';

const _field = Key('tmdb_credential_field');
const _verify = Key('tmdb_credential_verify');
const _connect = Key('discovery_connect_tmdb');

/// Credential in the (fake) platform secure storage, as a relaunch reads it.
Future<String?> _storedCredential() => const FlutterSecureStorage().read(
  key: TmdbCredentialStore.secureStorageKey,
);

/// Error shown under the credential field, or null.
String? _fieldError(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(_field)).decoration?.errorText;

SearchProvider _search(WidgetTester tester) =>
    tester.element(find.byType(MainPage)).read<SearchProvider>();

/// Types [credential] in the credential page and taps "Verify and save".
Future<void> _submit(WidgetTester tester, String credential) async {
  await tester.enterText(find.byKey(_field), credential);
  await tester.pump();
  await tester.tap(find.byKey(_verify));
  await pumpUntilSettled(tester);
}

/// Discover shows the trending grid: loaded, no TMDB invitation.
void _expectTrendingShown(WidgetTester tester) {
  final search = _search(tester);
  expect(search.isTrending, isTrue);
  expect(search.errorType, isNull);
  expect(search.items, isNotEmpty);
  expect(find.byKey(const Key('discovery_results_title')), findsOneWidget);
  expect(find.byKey(_connect), findsNothing);
}

void main() {
  group('first launch journey', () {
    testApp('should save a TMDB key only once TMDB accepts it, keep it across '
        'a relaunch and invite again once removed', (tester, app) async {
      // 1. First launch: the onboarding screen, then Discover's invitation.
      expect(find.byType(OnboardingPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await pumpUntilSettled(tester);
      expect(find.byType(OnboardingPage), findsNothing);

      await goToTab(tester, AppTab.discover);
      expect(find.byKey(_connect), findsOneWidget);
      expect(_search(tester).errorType, SearchErrorType.missingApiKey);
      expect(app.tmdb.requestCount, 0, reason: 'no key, no TMDB request');

      // 2. A key TMDB rejects (401): error shown, nothing stored.
      await tester.tap(find.byKey(_connect));
      await pumpUntilSettled(tester);
      expect(find.byType(TmdbCredentialPage), findsOneWidget);
      app.tmdb.fail(FakeTmdbFailure.unauthorized, pathPrefix: 'authentication');
      await _submit(tester, 'not-a-valid-tmdb-key');
      expect(app.tmdb.countFor('authentication'), 1);
      expect(_fieldError(tester), isNotNull);
      expect(find.byType(TmdbCredentialPage), findsOneWidget);
      expect(await _storedCredential(), isNull);
      expect(
        find.byKey(const Key('tmdb_credential_save_anyway')),
        findsNothing,
      );

      // 3. A key TMDB accepts: stored, back to Discover, trending loaded.
      app.tmdb.recover();
      await _submit(tester, testTmdbCredential);
      expect(app.tmdb.countFor('authentication'), 2);
      expect(await _storedCredential(), testTmdbCredential);
      expect(find.byType(TmdbCredentialPage), findsNothing);
      expect(app.tmdb.countFor('trending'), greaterThan(0));
      _expectTrendingShown(tester);

      // 4. Relaunch: the key is kept, no onboarding, Discover loads again.
      final trendingBefore = app.tmdb.countFor('trending');
      await restartTestApp(tester);
      expect(find.byType(TmdbCredentialPage), findsNothing);
      expect(await _storedCredential(), testTmdbCredential);
      await goToTab(tester, AppTab.discover);
      expect(app.tmdb.countFor('trending'), greaterThan(trendingBefore));
      _expectTrendingShown(tester);
      expect(app.tmdb.countFor('authentication'), 2);

      // 5. Remove the key from the Me tab: Discover invites again.
      await goToTab(tester, AppTab.me);
      final keyEntry = find.byKey(const Key('profile_tmdb_credential'));
      await tester.scrollUntilVisible(
        keyEntry,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ProfilePage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(keyEntry);
      await pumpUntilSettled(tester);
      await tester.tap(find.byKey(const Key('tmdb_credential_remove')));
      await pumpUntilSettled(tester);
      expect(find.byType(TmdbCredentialPage), findsNothing);
      expect(await _storedCredential(), isNull);

      await goToTab(tester, AppTab.discover);
      expect(find.byKey(_connect), findsOneWidget);
      expect(_search(tester).items, isEmpty);
      expect(app.tmdb.countFor('authentication'), 2);
    }, seed: const AppSeed(tmdbCredential: null));

    testApp(
      'should load Discover when a valid key is saved during onboarding',
      (tester, app) async {
        expect(find.byType(OnboardingPage), findsOneWidget);
        await tester.tap(find.byKey(const Key('onboarding_start')));
        await pumpUntilSettled(tester);

        // Tour: 3 cards -> Next x 3 reaches TMDB step.
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('onboarding_tour_next')));
          await pumpUntilSettled(tester);
        }

        expect(find.byType(TmdbCredentialPage), findsOneWidget);
        await _submit(tester, testTmdbCredential);
        expect(app.tmdb.countFor('authentication'), 1);
        expect(await _storedCredential(), testTmdbCredential);

        // Optional import step: skip -> onboarding completes.
        await tester.tap(find.byKey(const Key('onboarding_import_skip')));
        await pumpUntilSettled(tester);
        expect(find.byType(OnboardingPage), findsNothing);

        await goToTab(tester, AppTab.discover);
        _expectTrendingShown(tester);
      },
      seed: const AppSeed(tmdbCredential: null),
    );

    testApp(
      'should not show onboarding again after skipping, even without a key',
      (tester, app) async {
        expect(find.byType(OnboardingPage), findsOneWidget);
        await tester.tap(find.byKey(const Key('onboarding_skip')));
        await pumpUntilSettled(tester);
        expect(find.byType(OnboardingPage), findsNothing);

        await restartTestApp(tester);
        expect(find.byType(OnboardingPage), findsNothing);
        await goToTab(tester, AppTab.discover);
        expect(find.byKey(_connect), findsOneWidget);
      },
      seed: const AppSeed(tmdbCredential: null),
    );

    testApp(
      'should skip onboarding for existing users with local data',
      (tester, app) async {
        expect(find.byType(OnboardingPage), findsNothing);
      },
      seed: AppSeed(
        tmdbCredential: null,
        seen: [
          SeenItem(
            tmdbId: 550,
            type: MediaType.movie,
            title: 'Fight Club',
            seenDate: DateTime(2025),
          ),
        ],
      ),
    );

    testApp('should defer an incoming deep link until onboarding finishes', (
      tester,
      app,
    ) async {
      expect(find.byType(OnboardingPage), findsOneWidget);

      final encoded = ListShareCodec.encodeV2(const [
        SharedMediaEntry(550, MediaType.movie),
      ]);
      final uri = Uri.parse('mediavore://share?v=2&name=Weekend&d=$encoded');
      await app.openLink(tester, uri);

      // Deep link sheet must not appear behind onboarding.
      expect(find.text('Weekend'), findsNothing);
      expect(find.byType(OnboardingPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await pumpUntilSettled(tester);

      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.text('Weekend'), findsOneWidget);
    }, seed: const AppSeed(tmdbCredential: null));

    testApp(
      'should replay Welcome and Tour from Settings without touching the key',
      (tester, app) async {
        await goToTab(tester, AppTab.me);
        final settingsTile = find.byKey(const Key('profile_settings'));
        await tester.scrollUntilVisible(
          settingsTile,
          200,
          scrollable: find
              .descendant(
                of: find.byType(ProfilePage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(settingsTile);
        await pumpUntilSettled(tester);

        final reviewTile = find.byKey(const Key('settings_review_onboarding'));
        await tester.scrollUntilVisible(
          reviewTile,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(reviewTile);
        await pumpUntilSettled(tester);

        expect(find.byType(OnboardingPage), findsOneWidget);
        await tester.tap(find.byKey(const Key('onboarding_start')));
        await pumpUntilSettled(tester);
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('onboarding_tour_next')));
          await pumpUntilSettled(tester);
        }

        expect(find.byType(OnboardingPage), findsNothing);
        expect(await _storedCredential(), testTmdbCredential);
      },
    );
  });
}
