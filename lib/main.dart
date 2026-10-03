import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
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

const _localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final _supportedLocales = [
  for (final language in supportedAppLanguages) language.locale,
];

/// Device locales -> first supported language, else English.
Locale _resolveLocale(List<Locale>? deviceLocales, Iterable<Locale> _) =>
    resolveAppLanguage(deviceLocales ?? const []).locale;

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
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
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
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: _supportedLocales,
        localeListResolutionCallback: _resolveLocale,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  context.l10n.appStartupFailed(_error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
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
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: _supportedLocales,
        localeListResolutionCallback: _resolveLocale,
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.appLoading,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const MediaVoreApp();
  }
}

class MediaVoreApp extends StatefulWidget {
  const MediaVoreApp({super.key});

  @override
  State<MediaVoreApp> createState() => _MediaVoreAppState();
}

class _MediaVoreAppState extends State<MediaVoreApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // Keeps TMDB requests in sync when "System" follows the device.
    locator<LocaleService>().handleDeviceLocalesChanged();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final repo = locator<MediaRepository>();
            return SearchProvider(
              repo,
              localeService: locator<LocaleService>(),
            );
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final prefs = locator<SharedPreferences>();
            return SettingsProvider(
              prefs,
              locator<TmdbCredentialStore>(),
              localeService: locator<LocaleService>(),
            );
          },
        ),
        ChangeNotifierProvider(
          create: (context) => locator<AchievementProvider>(),
        ),
      ],
      builder: (context, child) {
        final settings = context.watch<SettingsProvider>();
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          localizationsDelegates: _localizationsDelegates,
          supportedLocales: _supportedLocales,
          locale: settings.locale,
          localeListResolutionCallback: _resolveLocale,
          // Keeps `intl` formatting (DateFormat, NumberFormat) on the app
          // language.
          builder: (context, child) => Builder(
            builder: (context) {
              Intl.defaultLocale = Localizations.localeOf(
                context,
              ).toLanguageTag();
              return child!;
            },
          ),
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
