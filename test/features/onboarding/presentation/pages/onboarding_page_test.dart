import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fake_file_picker.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SettingsProvider settings;
  late SearchProvider searchProvider;
  late LocaleService localeService;

  setUpAll(() {
    registerFallbackValue(ImportMode.append);
    registerFallbackValue(MediaType.movie);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localeService = LocaleService.withDeviceLocales(
      prefs,
      () => const [Locale('en')],
    );
    settings = SettingsProvider(
      prefs,
      FakeTmdbCredentialStore(),
      localeService: localeService,
    );

    mockRepository = MockMediaRepository();
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.applyLanguageChange(),
    ).thenAnswer((_) async => false);
    when(
      () => mockRepository.discoverMedia(
        page: any(named: 'page'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRepository.importAllData(
        any(),
        mode: any(named: 'mode'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async {});

    searchProvider = SearchProvider(
      mockRepository,
      localeService: localeService,
    );
  });

  Widget buildApp({bool reviewOnly = false, VoidCallback? onPopped}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ],
        child: Consumer<SettingsProvider>(
          builder: (context, s, _) => MaterialApp(
            theme: const DefaultLightPalette().toThemeData(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              for (final language in supportedAppLanguages) language.locale,
            ],
            locale: s.locale,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('open_onboarding'),
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => OnboardingPage(
                            reviewOnly: reviewOnly,
                            openUrl: (_) async => true,
                          ),
                        ),
                      );
                      onPopped?.call();
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> openOnboarding(
    WidgetTester tester, {
    bool reviewOnly = false,
    VoidCallback? onPopped,
  }) async {
    await tester.pumpWidget(
      buildApp(reviewOnly: reviewOnly, onPopped: onPopped),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_onboarding')));
    await tester.pumpAndSettle();
  }

  group('OnboardingPage', () {
    testWidgets('should switch language on the Welcome step', (tester) async {
      await openOnboarding(tester);

      expect(find.byKey(const Key('onboarding_step_welcome')), findsOneWidget);
      expect(find.text('Welcome to MediaVore'), findsOneWidget);

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue dans MediaVore'), findsOneWidget);
      expect(settings.appLanguageOverride?.code, 'fr');
    });

    testWidgets(
      'should walk through Welcome, 3-card Tour, TMDB Key and Import, then complete',
      (tester) async {
        var popped = false;
        await openOnboarding(tester, onPopped: () => popped = true);

        // Step 1: Welcome
        expect(
          find.byKey(const Key('onboarding_step_welcome')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('onboarding_start')));
        await tester.pumpAndSettle();

        // Step 2: Tour (3 cards + Back navigation)
        expect(find.byKey(const Key('onboarding_step_tour')), findsOneWidget);
        expect(find.text('Home & Discover'), findsOneWidget);

        await tester.tap(find.byKey(const Key('onboarding_tour_next')));
        await tester.pumpAndSettle();
        expect(find.text('Library & Together'), findsOneWidget);

        await tester.tap(find.byKey(const Key('onboarding_back')));
        await tester.pumpAndSettle();
        expect(find.text('Home & Discover'), findsOneWidget);

        await tester.tap(find.byKey(const Key('onboarding_tour_next')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('onboarding_tour_next')));
        await tester.pumpAndSettle();
        expect(find.text('Me & Your Data'), findsOneWidget);

        await tester.tap(find.byKey(const Key('onboarding_tour_next')));
        await tester.pumpAndSettle();

        // Step 3: TMDB Key (embedded TmdbCredentialPage)
        expect(find.byType(TmdbCredentialPage), findsOneWidget);
        await tester.tap(find.byKey(const Key('tmdb_credential_skip')));
        await tester.pumpAndSettle();

        // Step 4: Optional Import
        expect(find.byKey(const Key('onboarding_step_import')), findsOneWidget);
        await tester.tap(find.byKey(const Key('onboarding_import_skip')));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
        expect(settings.onboardingCompleted, isTrue);
      },
    );

    testWidgets('should complete onboarding immediately when Skip is tapped', (
      tester,
    ) async {
      var popped = false;
      await openOnboarding(tester, onPopped: () => popped = true);

      await tester.tap(find.byKey(const Key('onboarding_start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboarding_step_tour')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(settings.onboardingCompleted, isTrue);
    });

    testWidgets(
      'should show only Welcome and Tour in reviewOnly mode without touching onboardingCompleted',
      (tester) async {
        var popped = false;
        await openOnboarding(
          tester,
          reviewOnly: true,
          onPopped: () => popped = true,
        );

        await tester.tap(find.byKey(const Key('onboarding_start')));
        await tester.pumpAndSettle();

        // 3 cards; last card button says "Done" and pops directly.
        await tester.tap(find.byKey(const Key('onboarding_tour_next')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('onboarding_tour_next')));
        await tester.pumpAndSettle();
        expect(find.text('Done'), findsOneWidget);

        await tester.tap(find.byKey(const Key('onboarding_tour_next')));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
        expect(find.byType(TmdbCredentialPage), findsNothing);
        expect(settings.onboardingCompleted, isFalse);
      },
    );

    testWidgets(
      'should import a backup with preview on Step 4 and complete onboarding',
      (tester) async {
        final dir = Directory.systemTemp.createTempSync('onboarding_import_');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = File('${dir.path}/backup.mdv')
          ..writeAsBytesSync(
            ExportEnvelope(
              version: ExportEnvelope.currentVersion,
              exportedAt: DateTime(2026),
            ).toZipBytes(),
          );
        final previous = FilePickerPlatform.instance;
        FilePickerPlatform.instance = FakeFilePickerPlatform()
          ..files = [LocalPlatformFile(file.path)];
        addTearDown(() => FilePickerPlatform.instance = previous);

        var popped = false;
        await openOnboarding(tester, onPopped: () => popped = true);

        await tester.tap(find.byKey(const Key('onboarding_start')));
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('onboarding_tour_next')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('tmdb_credential_skip')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('onboarding_import_button')));
        for (var i = 0; i < 40; i++) {
          await tester.pump();
          if (find.text('Import Preview').evaluate().isNotEmpty) break;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
        }
        await tester.pumpAndSettle();

        // Preview dialog is shown.
        expect(find.text('Import Preview'), findsOneWidget);
        await tester.tap(find.text('Merge'));
        await tester.pumpAndSettle();

        verify(
          () => mockRepository.importAllData(
            any(),
            mode: ImportMode.merge,
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);
        expect(popped, isTrue);
        expect(settings.onboardingCompleted, isTrue);
      },
    );
  });
}
