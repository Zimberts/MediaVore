import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_sheet.dart';

import '../../helpers/pump_app.dart';

const _longText =
    'A deliberately long text that could never fit on a single line of a '
    'phone screen, to check that nothing overflows';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester, AppPalette palette) async {
    late BuildContext context;
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (c) {
            context = c;
            return const Text('Page');
          },
        ),
        palette: palette,
      ),
    );
    return context;
  }

  for (final palette in testPalettes) {
    final name = palette.id.name;
    final colors = palette.toExtension();

    group('showAppSheet on $name', () {
      testWidgets('should show the content under a grab handle', (
        tester,
      ) async {
        final context = await pumpHost(tester, palette);
        final result = showAppSheet<String>(
          context: context,
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).pop('done'),
            child: const Text('Apply'),
          ),
        );
        await tester.pumpAndSettle();

        final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
        expect(sheet.backgroundColor, colors.surface);
        expect(
          sheet.shape,
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        );

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        expect(await result, 'done');
      });

      testWidgets('should scroll a content taller than the screen', (
        tester,
      ) async {
        final context = await pumpHost(tester, palette);
        showAppSheet<void>(
          context: context,
          builder: (context) =>
              Column(children: [for (var i = 0; i < 60; i++) Text('Row $i')]),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final screen = tester.getSize(find.byType(MaterialApp));
        expect(
          tester.getSize(find.byType(BottomSheet)).height,
          lessThanOrEqualTo(screen.height * 0.88 + 0.01),
        );
        await tester.scrollUntilVisible(
          find.text('Row 59'),
          300,
          scrollable: find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('Row 59'), findsOneWidget);
      });
    });

    group('showAppDialog on $name', () {
      testWidgets('should complete with the value of the tapped action', (
        tester,
      ) async {
        final context = await pumpHost(tester, palette);
        final result = showAppDialog<bool>(
          context: context,
          title: 'Delete the list',
          message: _longText,
          actions: const [
            AppDialogAction(label: 'Cancel', value: false),
            AppDialogAction(label: 'Delete', value: true, danger: true),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Delete the list'), findsOneWidget);
        expect(find.text(_longText), findsOneWidget);
        expect(tester.takeException(), isNull);
        final delete = tester.widget<Text>(find.text('Delete'));
        final style = DefaultTextStyle.of(
          tester.element(find.text('Delete')),
        ).style;
        expect(delete.style?.color ?? style.color, colors.danger);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(await result, isTrue);
        expect(find.text('Delete the list'), findsNothing);
      });

      testWidgets('should offer a localized Close button without actions', (
        tester,
      ) async {
        final context = await pumpHost(tester, palette);
        final result = showAppDialog<void>(
          context: context,
          title: _longText,
          subtitle: 'Subtitle',
          content: const Text('Custom content'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Custom content'), findsOneWidget);
        expect(find.text('Subtitle'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await result;
        expect(find.text('Custom content'), findsNothing);
      });
    });

    group('showAppMenu on $name', () {
      testWidgets('should complete with the value of the tapped row', (
        tester,
      ) async {
        final context = await pumpHost(tester, palette);
        final result = showAppMenu<String>(
          context: context,
          title: 'Dune',
          items: const [
            AppMenuItem(
              value: 'open',
              label: 'Open',
              icon: Icons.movie,
              subtitle: _longText,
            ),
            AppMenuItem(
              value: 'delete',
              label: 'Delete this viewing',
              icon: Icons.delete_outline,
              danger: true,
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Dune'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<Text>(find.text('Delete this viewing')).style?.color,
          colors.danger,
        );
        expect(
          tester.widget<Text>(find.text('Open')).style?.color,
          colors.text,
        );

        await tester.tap(find.text('Delete this viewing'));
        await tester.pumpAndSettle();
        expect(await result, 'delete');
      });

      testWidgets('should complete with null when closed', (tester) async {
        final context = await pumpHost(tester, palette);
        final result = showAppMenu<String>(
          context: context,
          title: 'Sort by',
          items: const [AppMenuItem(value: 'a', label: 'Name')],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(await result, isNull);
      });
    });
  }
}
