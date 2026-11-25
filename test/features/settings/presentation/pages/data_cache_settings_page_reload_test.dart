import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_file_picker.dart';
import '../../../../helpers/mocks.dart';

class _MockSearchProvider extends Mock
    with ChangeNotifier
    implements SearchProvider {}

class _MockCacheAdminProvider extends Mock
    with ChangeNotifier
    implements CacheAdminProvider {}

class _MockAchievementProvider extends Mock
    with ChangeNotifier
    implements AchievementProvider {}

/// Idle storage state, as both providers expose it.
void _stubIdle(CacheAdminActions provider) {
  when(() => provider.cacheWarmupProgress).thenReturn(ValueNotifier(null));
  when(() => provider.isCacheLoading).thenReturn(false);
  when(() => provider.isDbSizeLoading).thenReturn(false);
  when(() => provider.isImporting).thenReturn(false);
  when(() => provider.cacheSize).thenReturn(0);
  when(() => provider.seenDbSize).thenReturn(0);
  when(() => provider.importProgress).thenReturn(0.0);
  when(() => provider.importStatus).thenReturn('');
}

/// Runs [action] then pumps, letting real I/O (file read, background
/// isolate) complete, until [until] is found.
Future<void> _tapUntil(WidgetTester tester, Finder target, Finder until) async {
  await tester.tap(target);
  for (var i = 0; i < 100 && until.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(until, findsOneWidget);
}

void main() {
  setUpAll(() => registerFallbackValue(ImportMode.append));

  // The app provides a CacheAdminProvider for the page's storage state: the
  // actions that rewrite user data must still go through SearchProvider,
  // which reloads every screen afterwards (#469).
  group('DataCacheSettingsPage with a CacheAdminProvider', () {
    late _MockSearchProvider search;
    late _MockCacheAdminProvider cacheAdmin;

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: const DefaultLightPalette().toThemeData(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SearchProvider>.value(value: search),
              ChangeNotifierProvider<CacheAdminProvider?>.value(
                value: cacheAdmin,
              ),
              ChangeNotifierProvider<AchievementProvider>.value(
                value: _MockAchievementProvider(),
              ),
              ChangeNotifierProvider<SettingsProvider>.value(
                value: SettingsProvider(
                  MockSharedPreferences(),
                  FakeTmdbCredentialStore(),
                ),
              ),
            ],
            child: const DataCacheSettingsPage(),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() {
      search = _MockSearchProvider();
      cacheAdmin = _MockCacheAdminProvider();
      _stubIdle(search);
      _stubIdle(cacheAdmin);
      when(
        () => search.importAllData(any(), mode: any(named: 'mode')),
      ).thenAnswer((_) async {});
      when(search.refetchMissingData).thenAnswer((_) async {});
    });

    testWidgets('should import through SearchProvider when the user '
        'replaces the data', (tester) async {
      final dir = Directory.systemTemp.createTempSync('mediavore_reload_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/backup.mdv')
        ..writeAsBytesSync(
          ExportEnvelope(
            version: 1,
            exportedAt: DateTime.utc(2025),
            seen: [
              SeenItemModel(
                tmdbId: 1,
                type: 'movie',
                title: 'A',
                seenDate: DateTime.utc(2025),
              ),
            ],
          ).toZipBytes(),
        );
      final previous = FilePickerPlatform.instance;
      FilePickerPlatform.instance = FakeFilePickerPlatform()
        ..files = [LocalPlatformFile(file.path)];
      addTearDown(() => FilePickerPlatform.instance = previous);
      await pumpPage(tester);

      await tester.scrollUntilVisible(
        find.byKey(DataCacheSettingsPage.importKey),
        200,
      );
      await _tapUntil(
        tester,
        find.byKey(DataCacheSettingsPage.importKey),
        find.byKey(DataCacheSettingsPage.importReplaceKey),
      );
      await tester.tap(find.byKey(DataCacheSettingsPage.importReplaceKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DataCacheSettingsPage.replaceConfirmKey));
      await tester.pumpAndSettle();

      verify(
        () => search.importAllData(any(), mode: ImportMode.replace),
      ).called(1);
      verifyNever(
        () => cacheAdmin.importAllData(any(), mode: any(named: 'mode')),
      );
    });

    testWidgets('should refetch the missing data through SearchProvider', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.update));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      verify(search.refetchMissingData).called(1);
      verifyNever(cacheAdmin.refetchMissingData);
    });
  });
}
