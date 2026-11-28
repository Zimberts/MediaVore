import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/settings/presentation/widgets/palette_picker_grid.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late SettingsProvider settings;
  late MockMediaRepository repository;
  late MockSharedPreferences mockPrefs;
  late MockAchievementProvider achievementProvider;

  setUp(() async {
    repository = MockMediaRepository();
    if (locator.isRegistered<MediaRepository>()) {
      await locator.unregister<MediaRepository>();
    }
    locator.registerSingleton<MediaRepository>(repository);

    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);

    settings = SettingsProvider(mockPrefs, FakeTmdbCredentialStore('key'));

    achievementProvider = MockAchievementProvider();
    const dummyAchievement = Achievement(
      id: 'first_movie',
      title: 'First Movie',
      description: 'Logged 1 movie',
      iconPath: 'icon',
      category: 'movies',
    );
    when(() => achievementProvider.achievements).thenReturn([dummyAchievement]);
    when(
      () => achievementProvider.families,
    ).thenReturn(groupAchievements([dummyAchievement]));
  });

  tearDown(() async {
    if (locator.isRegistered<MediaRepository>()) {
      await locator.unregister<MediaRepository>();
    }
  });

  Widget app() => MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<AchievementProvider>.value(
        value: achievementProvider,
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsPage(),
    ),
  );

  testWidgets('SettingsPage renders a segmented ThemeMode and palette cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(AppSegmented<ThemeMode>), findsOneWidget);
    expect(find.byType(AppSegmented<AppPaletteId>), findsNothing);
    expect(
      find.byType(PaletteSwatchCard),
      findsNWidgets(AppPalette.values.length),
    );

    // Tap dark mode in segmented control
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    verify(() => mockPrefs.setInt('themeMode', ThemeMode.dark.index)).called(1);
  });

  testWidgets('SettingsPage does not contain duplicate achievements tile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_achievements_tile')), findsNothing);
  });

  testWidgets('SettingsPage displays swipe mode switch and toggles setting', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const Key('settings_swipe_mode_switch'));
    expect(switchFinder, findsOneWidget);

    expect(settings.isSwipeModeEnabled, true);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(settings.isSwipeModeEnabled, false);
  });

  testWidgets('SettingsPage displays swipe reset tile and confirms reset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    unawaited(settings.setSwipeModeEnabled(true));
    when(() => repository.getSwipeDecisions()).thenAnswer(
      (_) async => [
        SwipeDecisionModel(
          tmdbId: 1,
          title: 'Title 1',
          decision: 'discarded',
          decidedAt: DateTime.now(),
        ),
        SwipeDecisionModel(
          tmdbId: 2,
          title: 'Title 2',
          decision: 'discarded',
          decidedAt: DateTime.now(),
        ),
      ],
    );
    when(() => repository.clearAllSwipeDecisions()).thenAnswer((_) async {});

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final resetTileFinder = find.byKey(const Key('settings_swipe_reset_tile'));
    expect(resetTileFinder, findsOneWidget);
    expect(find.text('2 discarded titles'), findsOneWidget);

    final resetButtonFinder = find.byKey(
      const Key('settings_swipe_reset_button'),
    );
    await tester.tap(resetButtonFinder);
    await tester.pumpAndSettle();

    // Confirm dialog is shown
    expect(
      find.byKey(const Key('settings_swipe_reset_confirm')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings_swipe_reset_confirm')));
    await tester.pumpAndSettle();

    verify(() => repository.clearAllSwipeDecisions()).called(1);
    expect(find.text('No discarded titles'), findsOneWidget);
  });
}
