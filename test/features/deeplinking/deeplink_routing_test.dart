import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

void main() {
  late MockMediaRepository mockRepository;
  late MockSharedPreferences mockSharedPreferences;
  late SearchProvider provider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockSharedPreferences = MockSharedPreferences();

    // Default stubs
    when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);

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

    // createList and addToList should be verifiable
    when(
      () => mockRepository.createList(any()),
    ).thenAnswer((_) async => Future.value());
    when(
      () => mockRepository.addToList(any(), any()),
    ).thenAnswer((_) async => Future.value());

    provider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockSharedPreferences);

    // Register mock repository in GetIt so widgets that use `locator` find it
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockRepository);
  });

  tearDown(() async {
    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
  });

  testWidgets('Import via link flow imports list and calls repository', (
    WidgetTester tester,
  ) async {
    final appThemeExt = AppThemeExtension(
      onWatchlist: Colors.green,
      likeHeart: Colors.red,
      ratingStar: Colors.yellow,
      visualSelection: Colors.blue,
      logicFlow: Colors.blue,
      dataValues: Colors.teal,
      constants: Colors.grey,
      functions: Colors.purple,
      structural: Colors.brown,
      comments: Colors.grey,
      badgeBg: Colors.grey,
      badgeBgSeen: Colors.grey,
      badgeText: Colors.white,
      warning: Colors.orange,
      error: Colors.red,
      success: Colors.green,
      info: Colors.blue,
      placeholder: Colors.grey,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: MaterialApp(
          theme: ThemeData().copyWith(extensions: [appThemeExt]),
          home: const SavedMediaPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open share/import modal by tapping the share icon in app bar
    final shareIcon = find.byIcon(Icons.share);
    expect(shareIcon, findsOneWidget);
    await tester.tap(shareIcon);
    await tester.pumpAndSettle();

    // In bottom sheet, tap 'Import via Link'
    final importLinkTile = find.text('Import via Link');
    expect(importLinkTile, findsOneWidget);
    await tester.tap(importLinkTile);
    await tester.pumpAndSettle();

    // Now the import link dialog should be visible with a TextField
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Provide a valid share link containing name and items
    final link = 'https://mediavore.app/share?name=MyList&items=1:movie,2:tv';
    await tester.enterText(textField, link);
    await tester.pumpAndSettle();

    // Tap the Import button in the dialog
    final importButton = find.text('Import');
    expect(
      importButton,
      findsWidgets,
    ); // there are multiple Import buttons; the dialog one should be present
    await tester.tap(importButton.first);
    await tester.pumpAndSettle();

    // Confirmation dialog should appear asking to Confirm Import; find the Confirm button there
    final confirmImport = find.widgetWithText(TextButton, 'Confirm');
    expect(confirmImport, findsWidgets);

    // Tap the confirmation 'Confirm' in the confirmation dialog
    await tester.tap(confirmImport.last);
    await tester.pumpAndSettle();

    // Verify repository.createList and addToList were called
    verify(() => mockRepository.createList('MyList')).called(1);
    // addToList will be called for parsed entries; verify at least once
    verify(
      () => mockRepository.addToList(any(), 'MyList'),
    ).called(greaterThanOrEqualTo(1));
  });
}
