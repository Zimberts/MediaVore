import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/mocks.dart';

class _DialogLauncher extends StatefulWidget {
  final List<String> entries;
  final String suggestedName;
  const _DialogLauncher({required this.entries, required this.suggestedName});

  @override
  State<_DialogLauncher> createState() => _DialogLauncherState();
}

class _DialogLauncherState extends State<_DialogLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) {
          final controller = TextEditingController(text: widget.suggestedName);
          return AlertDialog(
            title: const Text('Import List'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are about to import a list with ${widget.entries.length} items.',
                ),
                const SizedBox(height: 16),
                TextField(controller: controller),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final provider = context.read<SearchProvider>();
                  await provider.importList(controller.text, widget.entries);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Import'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
    when(() => mockRepository.createList(any())).thenAnswer((_) async {});
    when(() => mockRepository.addToList(any(), any())).thenAnswer((_) async {});
  });

  testWidgets(
    'Import dialog calls provider.importList and repository methods',
    (tester) async {
      final added = <int>[];
      when(() => mockRepository.addToList(any(), any())).thenAnswer((
        inv,
      ) async {
        final item = inv.positionalArguments[0] as MediaItem;
        added.add(item.id);
      });

      final mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getInt(any())).thenReturn(0);
      when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
      when(() => mockPrefs.getBool(any())).thenReturn(false);
      when(
        () => mockPrefs.setDouble(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      final settings = SettingsProvider(mockPrefs);
      final provider = SearchProvider(mockRepository);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
          ],
          child: MaterialApp(
            theme: DefaultLightPalette().toThemeData(),
            home: _DialogLauncher(
              entries: ['123:movie', 'bad_entry'],
              suggestedName: 'Imported',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Import List'), findsOneWidget);
      expect(find.textContaining('import a list with 2 items'), findsOneWidget);

      // Confirm import
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      // Only the valid entry should have been added
      expect(added, equals([123]));
    },
  );
}
