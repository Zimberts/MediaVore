import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_progress_bar.dart';
import 'package:mediavore/core/widgets/offline_banner.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/core/widgets/type_chip.dart';

import '../../helpers/pump_app.dart';

const _longText =
    'A deliberately long label that could never fit on a single line of a '
    'phone screen, to check that nothing overflows';

void main() {
  for (final palette in testPalettes) {
    final name = palette.id.name;
    final colors = palette.toExtension();

    group('TypeChip on $name', () {
      for (final (kind, en, fr) in [
        (MediaKind.movie, 'Movie', 'Film'),
        (MediaKind.series, 'Series', 'Série'),
        (MediaKind.book, 'Book', 'Livre'),
      ]) {
        testWidgets('should show an icon only and name ${kind.name}', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          for (final (locale, label) in [('en', en), ('fr', fr)]) {
            await tester.pumpWidget(
              testApp(
                TypeChip(kind: kind),
                palette: palette,
                locale: Locale(locale),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byIcon(kind.icon), findsOneWidget);
            expect(find.byType(Text), findsNothing);
            expect(
              tester.getSemantics(find.byType(TypeChip)),
              matchesSemantics(label: label),
            );
            expect(
              tester.getSize(find.byType(TypeChip)),
              const Size(TypeChip.size, TypeChip.size),
            );
            final icon = tester.widget<Icon>(find.byIcon(kind.icon));
            expect(icon.color, kind.color(colors));
          }
          handle.dispose();
        });
      }

      testWidgets('should add the extra text to the label', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          testApp(
            const TypeChip(kind: MediaKind.series, extra: '3'),
            palette: palette,
          ),
        );

        expect(find.text('3'), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(TypeChip)),
          matchesSemantics(label: 'Series, 3'),
        );
        handle.dispose();
      });
    });

    group('AppCard on $name', () {
      testWidgets('should draw a bordered surface', (tester) async {
        await tester.pumpWidget(
          testApp(
            const AppCard(padding: EdgeInsets.all(12), child: Text('Content')),
            palette: palette,
          ),
        );

        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(AppCard),
            matching: find.byType(Material),
          ),
        );
        expect(material.color, colors.surface);
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.side.color, colors.border);
        expect(shape.borderRadius, BorderRadius.circular(AppCard.radius));
        expect(find.text('Content'), findsOneWidget);
      });

      testWidgets('should be tappable when given onTap', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          testApp(
            AppCard(onTap: () => taps++, child: const Text(_longText)),
            palette: palette,
          ),
        );

        await tester.tap(find.byType(AppCard));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });
    });

    group('AppSegmented on $name', () {
      Widget segmented(String selected, ValueChanged<String> onChanged) =>
          testApp(
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppSegmented<String>(
                segments: const [
                  AppSegment(value: 'a', label: 'Lists'),
                  AppSegment(value: 'b', label: _longText),
                  AppSegment(value: 'c', label: 'Books', icon: Icons.menu_book),
                ],
                selected: selected,
                onChanged: onChanged,
              ),
            ),
            palette: palette,
          );

      testWidgets('should report the tapped segment', (tester) async {
        String? changed;
        await tester.pumpWidget(segmented('a', (v) => changed = v));

        await tester.tap(find.text('Books'));
        expect(changed, 'c');
        expect(tester.takeException(), isNull);
      });

      testWidgets('should mark the selected segment', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(segmented('a', (_) {}));

        expect(
          tester.getSemantics(find.text('Lists')),
          matchesSemantics(
            label: 'Lists',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.widget<Text>(find.text('Lists')).style?.color,
          colors.text,
        );
        expect(
          tester.widget<Text>(find.text('Books')).style?.color,
          colors.text2,
        );
        handle.dispose();
      });

      testWidgets('should keep a long label on one line', (tester) async {
        await tester.pumpWidget(segmented('b', (_) {}));

        expect(tester.widget<Text>(find.text(_longText)).maxLines, 1);
        expect(
          tester.getSize(find.byType(AppSegmented<String>)).height,
          kMinTapTarget,
        );
        expect(tester.takeException(), isNull);
      });
    });

    group('FilterChipRow on $name', () {
      testWidgets('should scroll and report taps', (tester) async {
        final tapped = <String>[];
        await tester.pumpWidget(
          testApp(
            FilterChipRow(
              chips: [
                for (final label in ['All', 'Movies', _longText, 'Books'])
                  AppFilterChip(
                    label: label,
                    selected: label == 'All',
                    onTap: () => tapped.add(label),
                  ),
              ],
            ),
            palette: palette,
          ),
        );

        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Movies'));
        expect(tapped, ['Movies']);

        expect(
          tester.widget<Text>(find.text('All')).style?.color,
          colors.onPrimary,
        );
        expect(
          tester.widget<Text>(find.text('Movies')).style?.color,
          colors.text,
        );

        await tester.scrollUntilVisible(
          find.text('Books'),
          200,
          scrollable: find.descendant(
            of: find.byType(FilterChipRow),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(find.text('Books'));
        expect(tapped, ['Movies', 'Books']);
      });
    });

    group('MediaProgressBar on $name', () {
      for (final kind in MediaKind.values) {
        testWidgets('should be tinted for ${kind.name}', (tester) async {
          await tester.pumpWidget(
            testApp(
              SizedBox(
                width: 200,
                child: MediaProgressBar(value: 0.25, kind: kind),
              ),
              palette: palette,
            ),
          );

          final bar = find.byType(MediaProgressBar);
          expect(tester.getSize(bar), const Size(200, 6));
          final fill = find.descendant(
            of: bar,
            matching: find.byType(DecoratedBox),
          );
          expect(tester.getSize(fill).width, 50);
          expect(
            (tester.widget<DecoratedBox>(fill).decoration as BoxDecoration)
                .color,
            kind.color(colors),
          );
        });
      }

      testWidgets('should clamp its value and expose it', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          testApp(
            const SizedBox(
              width: 200,
              child: MediaProgressBar(
                value: 3,
                kind: MediaKind.series,
                semanticLabel: '12 / 12 episodes',
              ),
            ),
            palette: palette,
          ),
        );

        expect(
          tester.getSemantics(find.byType(MediaProgressBar)),
          matchesSemantics(label: '12 / 12 episodes', value: '100 %'),
        );
        handle.dispose();
      });
    });

    group('SectionHeader on $name', () {
      testWidgets('should show the title alone without action', (tester) async {
        await tester.pumpWidget(
          testApp(const SectionHeader(title: 'Upcoming'), palette: palette),
        );

        expect(find.text('Upcoming'), findsOneWidget);
        expect(find.text('See all'), findsNothing);
      });

      testWidgets('should show a localized link and report taps', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          testApp(
            SectionHeader(title: _longText, onAction: () => taps++),
            palette: palette,
            locale: const Locale('fr'),
          ),
        );

        await tester.tap(find.text('Tout voir'));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should accept a custom link label', (tester) async {
        await tester.pumpWidget(
          testApp(
            SectionHeader(
              title: 'Achievements',
              actionLabel: 'See all · 3 of 15',
              onAction: () {},
            ),
            palette: palette,
          ),
        );

        expect(find.text('See all · 3 of 15'), findsOneWidget);
      });
    });

    group('OfflineBanner on $name', () {
      testWidgets('should show the default title and the message', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            const OfflineBanner(message: _longText),
            palette: palette,
            locale: const Locale('fr'),
          ),
        );

        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(find.textContaining('Hors ligne'), findsOneWidget);
        expect(find.textContaining(_longText), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should be announced as a live region', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          testApp(const OfflineBanner(), palette: palette),
        );

        expect(
          tester.getSemantics(find.byType(OfflineBanner)),
          matchesSemantics(label: 'Offline', isLiveRegion: true),
        );
        handle.dispose();
      });
    });
  }
}
