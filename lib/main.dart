import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/di/injection.config.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/services/background_task_service.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/search/presentation/pages/main_page.dart';

Future<void> main() async {
  debugPrint('--- App Starting ---');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapperApp());
}

class BootstrapperApp extends StatefulWidget {
  const BootstrapperApp({super.key});

  @override
  State<BootstrapperApp> createState() => _BootstrapperAppState();
}

class _BootstrapperAppState extends State<BootstrapperApp> {
  bool _isInit = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Allow the first frame to paint the spinner BEFORE starting any heavy init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Yield slightly time for the UI thread to push the frame
      await Future.delayed(const Duration(milliseconds: 250));

      await init(locator);
      
      // Setup Background Tasks (safe to call after isar is opened by locator)
      if (Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS) {
        try {
          BackgroundTaskService.initialize();
          BackgroundTaskService.registerDailySync();
        } catch (e) {
          debugPrint('Failed to init workmanager $e');
        }
      }

      if (mounted) setState(() => _isInit = true);
    } catch (e, stackTrace) {
      debugPrint('Fatal error during initialization: $e');
      debugPrint(stackTrace.toString());
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to start app:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInit) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text('Loading MediaVore...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    return const MediaVoreApp();
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
