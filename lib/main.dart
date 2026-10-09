import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/di/injection.config.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/services/background_task_service.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/search/presentation/pages/main_page.dart';

Future<void> main() async {
  debugPrint('--- App Starting ---');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapperApp());
}

/// Startup work run by [BootstrapperApp]. Safe to call again after a failure.
Future<void> bootstrapServices() async {
  // A previous attempt may have failed midway: release what it opened and
  // clear partial registrations so `init` can register everything again.
  if (locator.isRegistered<Isar>()) {
    final isar = locator<Isar>();
    if (isar.isOpen) await isar.close();
  }
  await locator.reset();

  await init(locator);

  // Background sync is best-effort: a failure here must not block startup.
  final isMobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (isMobile) {
    try {
      await BackgroundTaskService.initialize();
      await BackgroundTaskService.registerDailySync();
    } catch (e, stackTrace) {
      debugPrint('Failed to init workmanager: $e');
      debugPrint(stackTrace.toString());
    }
  }
}

class BootstrapperApp extends StatefulWidget {
  const BootstrapperApp({
    super.key,
    this.initializer = bootstrapServices,
    this.app = const MediaVoreApp(),
  });

  final Future<void> Function() initializer;
  final Widget app;

  @override
  State<BootstrapperApp> createState() => _BootstrapperAppState();
}

class _BootstrapperAppState extends State<BootstrapperApp> {
  bool _isInit = false;
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Allow the first frame to paint the spinner BEFORE starting any heavy init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (_isLoading) return;
    _isLoading = true;
    if (_error != null) setState(() => _error = null);
    try {
      // Yield slightly time for the UI thread to push the frame
      await Future.delayed(const Duration(milliseconds: 250));

      await widget.initializer();

      if (mounted) setState(() => _isInit = true);
    } catch (e, stackTrace) {
      debugPrint('Fatal error during initialization: $e');
      debugPrint(stackTrace.toString());
      if (mounted) setState(() => _error = e);
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInit) return widget.app;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: _error == null
          ? const _LoadingScreen()
          : _StartupErrorScreen(error: _error!, onRetry: _initializeApp),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'MediaVore could not start',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Something went wrong while loading your data. '
                  'Please try again.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: Text(
                    'Technical details',
                    style: theme.textTheme.bodySmall,
                  ),
                  children: [
                    SelectableText(
                      error.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
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
            return SettingsProvider(prefs, locator<TmdbCredentialStore>());
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
