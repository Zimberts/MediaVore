import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockMediaRepository;

  setUp(() {
    mockMediaRepository = MockMediaRepository();
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
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

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: DefaultLightPalette().toThemeData(),
      home: const ActorDetailPage(actorId: tActorId, actorName: tActorName),
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

    // AppBar title + Body title
    expect(find.text(tActorName), findsAtLeastNWidgets(2));
    expect(find.text('1974-11-11'), findsOneWidget);
    expect(find.text('Los Angeles, California, USA'), findsOneWidget);
    expect(find.text('A talented actor.'), findsOneWidget);
    expect(find.text('Known For'), findsOneWidget);

    // Ensure the known for list is scrolled into view or rendered
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
  });

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
