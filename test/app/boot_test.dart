import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/navigation/app_tab_bar.dart';
import 'package:mediavore/core/services/background_task_service.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';

import 'harness.dart';

void main() {
  group('app boot', () {
    testApp('should show every tab without real network when a key is set', (
      tester,
      app,
    ) async {
      expect(find.byType(AppTabBar), findsOneWidget);
      for (final tab in AppTab.visibleTabs) {
        expect(find.byKey(ValueKey(tab)), findsOneWidget);
      }
      expect(find.byType(TmdbCredentialPage), findsNothing);
      // Every TMDB request reached the fake; any other is in `unhandled`.
      expect(app.tmdb.requestCount, greaterThan(0));
      expect(app.tmdb.unhandled, isEmpty);
      // Images came from the fake cache, never from image.tmdb.org.
      expect(app.images.requests, isNotEmpty);
      // The daily sync was scheduled on the fake, never on the host.
      expect(app.workmanager.registered, [fetchTaskIdentifier]);
    });

    testApp('should reach every tab', (tester, app) async {
      for (final tab in AppTab.visibleTabs) {
        await goToTab(tester, tab);
        final bar = tester.widget<AppTabBar>(find.byType(AppTabBar));
        expect(bar.selected, tab);
      }
    });

    testApp('should open the credential screen when no key is stored', (
      tester,
      app,
    ) async {
      expect(find.byType(TmdbCredentialPage), findsOneWidget);
      expect(app.tmdb.requestCount, 0);
    }, seed: const AppSeed(tmdbCredential: null));
  });
}
