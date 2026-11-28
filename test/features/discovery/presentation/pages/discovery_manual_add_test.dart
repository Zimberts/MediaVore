import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/manual_media_form_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockMediaRepository mockRepo;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  late DiscoveryProvider discoveryProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    mockRepo = MockMediaRepository();
    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepo.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepo.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepo.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepo.getListPreviews(any())).thenAnswer((_) async => []);
    when(
      () => mockRepo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepo.searchMedia(
        any(),
        page: any(named: 'page'),
        type: any(named: 'type'),
        genreIds: any(named: 'genreIds'),
        releaseYear: any(named: 'releaseYear'),
        minRating: any(named: 'minRating'),
        originalLanguage: any(named: 'originalLanguage'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => mockRepo.getTrendingMedia(page: any(named: 'page')),
    ).thenAnswer((_) async => const []);
    when(
      () => mockRepo.searchPeople(any(), page: any(named: 'page')),
    ).thenAnswer((_) async => const []);
    searchProvider = SearchProvider(mockRepo);
    settingsProvider = SettingsProvider(prefs, FakeTmdbCredentialStore());
    discoveryProvider = DiscoveryProvider();
  });

  group('DiscoveryPage manual add entry points', () {
    testWidgets(
      'should show add manual buttons and open ManualMediaFormPage pre-filled',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SearchProvider>.value(
                value: searchProvider,
              ),
              ChangeNotifierProvider<SettingsProvider>.value(
                value: settingsProvider,
              ),
              ChangeNotifierProvider<DiscoveryProvider>.value(
                value: discoveryProvider,
              ),
            ],
            child: testApp(const DiscoveryPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('discovery_add_manual')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('discovery_search_field')),
          'Obscure Short',
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        final emptyAdd = find.byKey(const Key('discovery_empty_add_manual'));
        expect(emptyAdd, findsOneWidget);

        await tester.tap(emptyAdd);
        await tester.pumpAndSettle();

        expect(find.byType(ManualMediaFormPage), findsOneWidget);
        expect(find.text('Obscure Short'), findsOneWidget);
      },
    );
  });
}
