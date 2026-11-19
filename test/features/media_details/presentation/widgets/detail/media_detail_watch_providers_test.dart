import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_watch_providers.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTmdbCredentialStore extends Mock implements TmdbCredentialStore {}

void main() {
  late SharedPreferences prefs;
  late MockTmdbCredentialStore credentials;
  late SettingsProvider settingsProvider;

  const testPayload = {
    'FR': {
      'link': 'https://www.themoviedb.org/movie/550/watch?locale=FR',
      'flatrate': [
        {
          'logo_path': '/netflix.jpg',
          'provider_id': 8,
          'provider_name': 'Netflix',
          'display_priority': 0,
        },
      ],
      'rent': [
        {
          'logo_path': '/canal.jpg',
          'provider_id': 381,
          'provider_name': 'Canal VOD',
          'display_priority': 1,
        },
      ],
    },
    'US': {
      'link': 'https://www.themoviedb.org/movie/550/watch?locale=US',
      'flatrate': [
        {
          'logo_path': '/hulu.jpg',
          'provider_id': 15,
          'provider_name': 'Hulu',
          'display_priority': 1,
        },
      ],
    },
    'GB': {
      'link': 'https://www.themoviedb.org/movie/550/watch?locale=GB',
      'flatrate': <dynamic>[],
      'rent': <dynamic>[],
    },
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    credentials = MockTmdbCredentialStore();
    when(() => credentials.credential).thenReturn('');
    settingsProvider = SettingsProvider(prefs, credentials);
  });

  Widget buildTestWidget({
    Map<String, dynamic>? providers = testPayload,
    Future<bool> Function(Uri url)? onOpenUrl,
    Locale locale = const Locale('fr'),
  }) {
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: settingsProvider,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaDetailWatchProviders(
              watchProviders: providers,
              openUrl: onOpenUrl ?? (_) async => true,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'displays French offers separated into Abonnement and Location when region is FR',
    (tester) async {
      await settingsProvider.setWatchProvidersCountry('FR');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('Où regarder'), findsOneWidget);

      // Categories
      expect(find.byKey(const Key('watch_providers_flatrate')), findsOneWidget);
      expect(find.text('Abonnement'), findsOneWidget);
      expect(find.byTooltip('Netflix'), findsOneWidget);

      expect(find.byKey(const Key('watch_providers_rent')), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.byTooltip('Canal VOD'), findsOneWidget);

      // US offers must NOT appear
      expect(find.byTooltip('Hulu'), findsNothing);

      // JustWatch attribution is visible
      expect(find.text('Données fournies par JustWatch'), findsOneWidget);
    },
  );

  testWidgets('displays only US offers when region is set to US', (
    tester,
  ) async {
    await settingsProvider.setWatchProvidersCountry('US');

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Où regarder'), findsOneWidget);
    expect(find.text('Abonnement'), findsOneWidget);
    expect(find.byTooltip('Hulu'), findsOneWidget);

    // French offers must NOT appear
    expect(find.byTooltip('Netflix'), findsNothing);
    expect(find.byTooltip('Canal VOD'), findsNothing);
    expect(find.text('Location'), findsNothing);
  });

  testWidgets('renders nothing when country has no offers', (tester) async {
    // GB has empty categories
    await settingsProvider.setWatchProvidersCountry('GB');

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Où regarder'), findsNothing);
    expect(find.text('Données fournies par JustWatch'), findsNothing);
    expect(find.byType(MediaDetailWatchProviders), findsOneWidget);
  });

  testWidgets('renders nothing when country is not in payload', (tester) async {
    await settingsProvider.setWatchProvidersCountry('DE');

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Où regarder'), findsNothing);
    expect(find.text('Données fournies par JustWatch'), findsNothing);
  });

  testWidgets('renders nothing when watchProviders is null or empty', (
    tester,
  ) async {
    await settingsProvider.setWatchProvidersCountry('FR');

    await tester.pumpWidget(buildTestWidget(providers: null));
    await tester.pumpAndSettle();
    expect(find.text('Où regarder'), findsNothing);

    await tester.pumpWidget(buildTestWidget(providers: {}));
    await tester.pumpAndSettle();
    expect(find.text('Où regarder'), findsNothing);
  });

  testWidgets('tapping on block opens the JustWatch link', (tester) async {
    await settingsProvider.setWatchProvidersCountry('FR');
    Uri? openedUri;

    await tester.pumpWidget(
      buildTestWidget(
        onOpenUrl: (uri) async {
          openedUri = uri;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('watch_providers_block')));
    await tester.pump();

    expect(openedUri, isNotNull);
    expect(
      openedUri.toString(),
      equals('https://www.themoviedb.org/movie/550/watch?locale=FR'),
    );
  });

  testWidgets('has accessible semantics and tooltip for providers', (
    tester,
  ) async {
    await settingsProvider.setWatchProvidersCountry('FR');

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final netflixSemantics = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == 'Netflix',
    );
    expect(netflixSemantics, findsOneWidget);

    final tooltip = tester.widget<Tooltip>(
      find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Netflix',
      ),
    );
    expect(tooltip.message, equals('Netflix'));
  });
}
