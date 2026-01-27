import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/core/theme/app_palette.dart';

void main() {
  late MockMediaRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepo = MockMediaRepository();
    when(() => mockRepo.getAllListNames()).thenAnswer((_) async =>
    [
      'watchlist'
    ]);
    when(() => mockRepo.getListEntries(any())).thenAnswer((_) async =>
    <String>[
    ]);
    when(() => mockRepo.getListPreviews(any())).thenAnswer((_) async =>
    <
        MediaItemPreview>[]);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => mockRepo.getWatchlistEntries()).thenAnswer((_) async =>
    <String>[
    ]);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(() => mockRepo.getNotifiedItems()).thenAnswer((_) async =>
    <
        NotifiedItem>[]);
  });


  testWidgets(
      'MediaStatsPage shows empty state when no seen items', (tester) async {
    final provider = SearchProvider(mockRepo);

    final appThemeExt = AppThemeExtension(
      onWatchlist: Colors.red,
      likeHeart: Colors.pink,
      ratingStar: Colors.amber,
      visualSelection: Colors.blue,
      logicFlow: Colors.green,
      dataValues: Colors.teal,
      constants: Colors.grey,
      functions: Colors.black,
      structural: Colors.brown,
      comments: Colors.blueGrey,
      badgeBg: Colors.grey,
      badgeBgSeen: Colors.black,
      badgeText: Colors.white,
      warning: Colors.orange,
      error: Colors.red,
      success: Colors.green,
      info: Colors.blue,
      placeholder: Colors.grey,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [appThemeExt]),
        home: ChangeNotifierProvider<SearchProvider>.value(
          value: provider,
          child: const MediaStatsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No data yet. Start watching!'), findsOneWidget);
  });
}