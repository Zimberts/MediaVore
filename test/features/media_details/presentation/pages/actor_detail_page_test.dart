import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/top_scrim_gradient.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/mocks.dart';

class MockSearchProvider extends Mock implements SearchProvider {}

void main() {
  late MockMediaRepository mockMediaRepository;
  late MockSearchProvider mockSearchProvider;

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    mockSearchProvider = MockSearchProvider();
    when(() => mockSearchProvider.seenItems).thenReturn(const []);

    if (locator.isRegistered<MediaRepository>()) {
      locator.unregister<MediaRepository>();
    }
    locator.registerLazySingleton<MediaRepository>(() => mockMediaRepository);
  });

  tearDown(() {
    locator.reset();
  });

  const tActorId = 1;
  const tActorName = 'Leonardo DiCaprio';
  const tActorDetails = ActorDetails(
    id: tActorId,
    name: tActorName,
    biography: 'A talented actor.',
    birthday: '1974-11-11',
    placeOfBirth: 'Los Angeles, California, USA',
    profilePath: '/leo.jpg',
    items: [
      MediaItem(
        id: 1,
        title: 'Inception',
        overview: 'A mind-bending thriller',
        releaseDate: '2010-07-16',
        posterPath: '/poster.jpg',
        mediaType: MediaType.movie,
      ),
    ],
  );

  Widget createWidgetUnderTest({
    SearchProvider? searchProvider,
    Locale locale = const Locale('en'),
    int personId = tActorId,
    String personName = tActorName,
  }) {
    return ChangeNotifierProvider<SearchProvider?>.value(
      value: searchProvider ?? mockSearchProvider,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('fr')],
        theme: AppPalette.paper.toThemeData(),
        home: ActorDetailPage(actorId: personId, actorName: personName),
      ),
    );
  }

  testWidgets('displays loading indicator initially', (
    WidgetTester tester,
  ) async {
    when(
      () => mockMediaRepository.getActorDetails(tActorId),
    ).thenAnswer((_) async => tActorDetails);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(tActorName), findsAtLeastNWidgets(1));
  });

  testWidgets('displays actor details when loading is successful', (
    WidgetTester tester,
  ) async {
    when(
      () => mockMediaRepository.getActorDetails(tActorId),
    ).thenAnswer((_) async => tActorDetails);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pumpAndSettle();

    // The header artwork is topped with a readability scrim.
    expect(find.byType(TopScrimGradient), findsOneWidget);

    // AppBar title + Body title
    expect(find.text(tActorName), findsAtLeastNWidgets(2));
    expect(find.text('1974-11-11'), findsOneWidget);
    expect(find.text('Los Angeles, California, USA'), findsOneWidget);
    expect(find.text('A talented actor.'), findsOneWidget);

    final knownFor = find.text('Known For');
    await tester.scrollUntilVisible(
      knownFor,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(knownFor, findsOneWidget);

    final inception = find.text('Inception');
    await tester.scrollUntilVisible(
      inception,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(inception, findsOneWidget);
  });

  testWidgets('displays director/creator section when person directed titles', (
    WidgetTester tester,
  ) async {
    const tDirectorDetails = ActorDetails(
      id: 2,
      name: 'Christopher Nolan',
      biography: 'Renowned director.',
      crewItems: [
        MediaItem(
          id: 1,
          title: 'Inception',
          overview: 'Dream within a dream',
          releaseDate: '2010-07-16',
          mediaType: MediaType.movie,
        ),
        MediaItem(
          id: 2,
          title: 'Oppenheimer',
          overview: 'Father of the atomic bomb',
          releaseDate: '2023-07-21',
          mediaType: MediaType.movie,
        ),
      ],
      items: [
        MediaItem(
          id: 3,
          title: 'Cameo Role',
          overview: 'Brief appearance',
          releaseDate: '2005-01-01',
          mediaType: MediaType.movie,
        ),
      ],
    );

    when(
      () => mockMediaRepository.getActorDetails(2),
    ).thenAnswer((_) async => tDirectorDetails);

    await tester.pumpWidget(
      createWidgetUnderTest(
        personId: 2,
        personName: 'Christopher Nolan',
        locale: const Locale('fr'),
      ),
    );
    await tester.pumpAndSettle();

    // Section "Réalisation / Création"
    final directing = find.text('Réalisation / Création');
    await tester.scrollUntilVisible(
      directing,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(directing, findsOneWidget);
    expect(find.text('Oppenheimer'), findsOneWidget);
    expect(find.text('Inception'), findsOneWidget);

    // Section "Interprète"
    final acting = find.text('Interprète');
    await tester.scrollUntilVisible(
      acting,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(acting, findsOneWidget);
    expect(find.text('Cameo Role'), findsOneWidget);
  });

  testWidgets('shows initials placeholder when profilePath is null', (
    WidgetTester tester,
  ) async {
    const tNoPhotoDetails = ActorDetails(
      id: 3,
      name: 'Jane Doe',
      profilePath: null,
    );

    when(
      () => mockMediaRepository.getActorDetails(3),
    ).thenAnswer((_) async => tNoPhotoDetails);

    await tester.pumpWidget(
      createWidgetUnderTest(personId: 3, personName: 'Jane Doe'),
    );
    await tester.pumpAndSettle();

    // Initials "JD"
    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('displays seen count and checkmark badge on seen titles', (
    WidgetTester tester,
  ) async {
    when(() => mockSearchProvider.seenItems).thenReturn([
      SeenItem(
        id: 1,
        tmdbId: 1, // Inception is seen
        type: MediaType.movie,
        title: 'Inception',
        seenDate: DateTime(2023, 1, 1),
      ),
    ]);

    const tPersonWithSeen = ActorDetails(
      id: 1,
      name: 'Leonardo DiCaprio',
      items: [
        MediaItem(
          id: 1,
          title: 'Inception',
          overview: 'Overview',
          releaseDate: '2010-07-16',
          mediaType: MediaType.movie,
        ),
        MediaItem(
          id: 99,
          title: 'Titanic',
          overview: 'Overview',
          releaseDate: '1997-12-19',
          mediaType: MediaType.movie,
        ),
      ],
    );

    when(
      () => mockMediaRepository.getActorDetails(1),
    ).thenAnswer((_) async => tPersonWithSeen);

    await tester.pumpWidget(createWidgetUnderTest(locale: const Locale('fr')));
    await tester.pumpAndSettle();

    // Counter "1 sur 2 vus"
    expect(find.text('1 sur 2 vus'), findsOneWidget);

    // Checkmark icon on seen item
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets(
    'expands and collapses biography when Read more / Show less is tapped',
    (WidgetTester tester) async {
      const longBio =
          'Line 1 of biography.\nLine 2 of biography.\nLine 3 of biography.\n'
          'Line 4 of biography.\nLine 5 of biography.\nLine 6 of biography.';
      const tBioDetails = ActorDetails(
        id: 1,
        name: 'Leonardo DiCaprio',
        biography: longBio,
      );

      when(
        () => mockMediaRepository.getActorDetails(1),
      ).thenAnswer((_) async => tBioDetails);

      await tester.pumpWidget(
        createWidgetUnderTest(locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      final readMoreFinder = find.text('Read more');
      await tester.scrollUntilVisible(
        readMoreFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(readMoreFinder, findsOneWidget);

      await tester.tap(readMoreFinder);
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
    },
  );

  testWidgets('displays error message when loading fails', (
    WidgetTester tester,
  ) async {
    when(
      () => mockMediaRepository.getActorDetails(tActorId),
    ).thenThrow(Exception('Network error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Failed to load actor details'), findsOneWidget);
  });
}
