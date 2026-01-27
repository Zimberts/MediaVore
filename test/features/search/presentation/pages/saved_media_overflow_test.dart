import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import '../../../../helpers/mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMediaRepository mockRepository;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;
  late MockSharedPreferences mockPrefs;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeSeenItem());
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(const MediaItem(id: 1, title: 'T', overview: '', releaseDate: ''));
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    mockPrefs = MockSharedPreferences();

    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.markAsSeen(any())).thenAnswer((_) async => Future.value());
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => []);

    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);

    searchProvider = SearchProvider(mockRepository);
    settingsProvider = SettingsProvider(mockPrefs);
  });

  testWidgets('SavedMediaPage AppBar overflows with very long list name at small width', (WidgetTester tester) async {
    // Set a narrow logical width to reproduce overflow
    final binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
    binding.window.physicalSizeTestValue = const Size(360, 800);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    // Make repository report a very long list name
    final longName = List.filled(200, 'A').join();
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist', longName]);

    // Recreate provider after mocking and register repo in service locator
    locator.registerSingleton<MediaRepository>(mockRepository);
    searchProvider = SearchProvider(mockRepository);

    final errors = <FlutterErrorDetails>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ],
        child: MaterialApp(
          theme: DefaultLightPalette().toThemeData(),
          home: const SavedMediaPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    // Open list picker (tap the AppBar title which shows 'Watchlist' initially)
    await tester.tap(find.text('Watchlist'));
    await tester.pumpAndSettle();

    // Tap the long list name inside the bottom sheet to select it
    await tester.tap(find.text(longName));
    await tester.pumpAndSettle();

    // Restore the previous handler
    FlutterError.onError = oldOnError;

    // Expect that there are NO overflow errors (this should fail before the fix)
    final hasOverflow = errors.any((d) => d.exceptionAsString().contains('overflowed') || d.exceptionAsString().contains('Overflow'));
    expect(hasOverflow, isFalse, reason: 'Expected no RenderFlex overflow when selecting a very long list name');
  });
}
