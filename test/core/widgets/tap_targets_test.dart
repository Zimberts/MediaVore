import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/section_header.dart';

import '../../helpers/pump_app.dart';

/// Every interactive element of the shared components must offer a touch
/// area of at least 48 x 48 dp (design v1.5), whatever its visual size.
void main() {
  void expectTarget(WidgetTester tester, Finder finder, String what) {
    final size = tester.getSize(finder);
    expect(
      size.width,
      greaterThanOrEqualTo(kMinTapTarget),
      reason: '$what: width ${size.width}',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(kMinTapTarget),
      reason: '$what: height ${size.height}',
    );
  }

  /// A tap [inset] dp inside each corner of a 48 dp square centered on
  /// [visual] must reach the control.
  Future<void> expectReachable(
    WidgetTester tester,
    Finder visual,
    int Function() taps,
    String what,
  ) async {
    final center = tester.getCenter(visual);
    const reach = kMinTapTarget / 2 - 1;
    var expected = taps();
    for (final offset in const [
      Offset(0, -reach),
      Offset(0, reach),
      Offset(-reach, 0),
      Offset(reach, 0),
    ]) {
      await tester.tapAt(center + offset);
      await tester.pump();
      expected++;
      expect(taps(), expected, reason: '$what: tap at $offset from center');
    }
  }

  Widget components({required VoidCallback onTap}) => testApp(
    builder: (context, child) => AppMessageHost(child: child!),
    Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(title: 'Section', onAction: onTap),
          AppSegmented<int>(
            segments: const [
              AppSegment(value: 0, label: 'One'),
              AppSegment(value: 1, label: 'Two'),
            ],
            selected: 0,
            onChanged: (_) => onTap(),
          ),
          FilterChipRow(
            chips: [
              AppFilterChip(label: 'A', onTap: onTap),
              AppFilterChip(label: 'Long chip', selected: true, onTap: onTap),
            ],
          ),
          AppCard(onTap: onTap, child: const Text('Card')),
          Material(
            child: AppTapTarget(
              onTap: onTap,
              semanticLabel: 'Seen',
              child: const Icon(Icons.check_box_outline_blank, size: 20),
            ),
          ),
          SizedBox(
            width: 60,
            child: MediaPosterCard(
              data: const MediaPosterData(
                title: 'Dune',
                kind: MediaKind.movie,
                caption: '2021',
              ),
              onTap: onTap,
              action: IconButton(
                icon: const Icon(Icons.bookmark_border, size: 18),
                tooltip: 'Add to watchlist',
                onPressed: onTap,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  group('Tap targets of the shared components', () {
    testWidgets('should all be at least 48 x 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(components(onTap: () => taps++));

      expectTarget(
        tester,
        find.ancestor(
          of: find.text('See all'),
          matching: find.byType(AppTapTarget),
        ),
        'section link',
      );
      // The link text is much smaller than its touch area.
      expect(
        tester.getSize(find.text('See all')).height,
        lessThan(kMinTapTarget),
      );
      for (final chip in ['A', 'Long chip']) {
        expectTarget(
          tester,
          find.ancestor(
            of: find.text(chip),
            matching: find.byType(AppTapTarget),
          ),
          'chip $chip',
        );
      }
      expectTarget(
        tester,
        find.ancestor(
          of: find.byIcon(Icons.check_box_outline_blank),
          matching: find.byType(AppTapTarget),
        ),
        'icon target',
      );
      expectTarget(tester, find.byType(MediaPosterCard), 'poster');
      expectTarget(tester, find.byType(IconButton), 'poster action');
      expectTarget(tester, find.byType(AppCard), 'card');

      // Controls whose visual is under 48 dp: the area around it responds.
      await expectReachable(tester, find.text('See all'), () => taps, 'link');
      await expectReachable(tester, find.text('A'), () => taps, 'chip');
      await expectReachable(tester, find.text('Two'), () => taps, 'segment');
      await expectReachable(
        tester,
        find.byIcon(Icons.check_box_outline_blank),
        () => taps,
        'icon target',
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('should hold for the message action', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(components(onTap: () {}));

      showAppMessage('Removed', actionLabel: 'Undo', onAction: () {});
      await tester.pump();

      expectTarget(tester, find.widgetWithText(TextButton, 'Undo'), 'undo');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('should hold for dialog buttons and menu rows', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(components(onTap: () {}));
      final context = tester.element(find.text('Section'));

      unawaited(
        showAppDialog<bool>(
          context: context,
          title: 'Title',
          message: 'Message',
          actions: const [
            AppDialogAction(label: 'No', value: false),
            AppDialogAction(label: 'OK', value: true),
          ],
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['No', 'OK']) {
        expectTarget(tester, find.widgetWithText(TextButton, label), label);
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      unawaited(
        showAppMenu<int>(
          context: context,
          title: 'Menu',
          items: const [
            AppMenuItem(value: 1, label: 'A'),
            AppMenuItem(value: 2, label: 'B', icon: Icons.sort),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expectTarget(
        tester,
        find.ancestor(of: find.text('B'), matching: find.byType(InkWell)),
        'menu row',
      );
      expectTarget(tester, find.widgetWithText(TextButton, 'Close'), 'close');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
