import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/di/injection.config.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/search/presentation/pages/main_page.dart';

Future<void> main() async {
  debugPrint('--- App Starting ---');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // DefinitionsLoader should be provided by generated DI (injection.config.dart).
    // Avoid manual registration here; run codegen to ensure it's registered.

    await init(locator);
    runApp(const MediaVoreApp());
  } catch (e, stackTrace) {
    debugPrint('Fatal error during initialization: $e');
    debugPrint(stackTrace.toString());

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to start app:\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MediaVoreApp extends StatelessWidget {
  const MediaVoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final repo = locator<MediaRepository>();
            return SearchProvider(repo);
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final prefs = locator<SharedPreferences>();
            return SettingsProvider(prefs);
          },
        ),
        ChangeNotifierProvider(
          create: (context) => locator<AchievementProvider>(),
        ),
      ],
      builder: (context, child) {
        final settings = context.watch<SettingsProvider>();
        return MaterialApp(
          title: 'MediaVore',
          theme: settings.lightPalette.toThemeData(),
          darkTheme: settings.darkPalette.toThemeData(),
          themeMode: settings.themeMode,
          home: const MainPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
