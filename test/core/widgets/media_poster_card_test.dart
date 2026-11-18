import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';

import '../../helpers/pump_app.dart';
import '../theme/contrast.dart';

const _longTitle =
    'The Extraordinarily Long and Winding Chronicle of a Title That Simply '
    'Refuses to End, Part Seven: The Return of the Subtitle';

void main() {
  late ui.Image white;

  setUpAll(() => white = solidImage(const Color(0xFFFFFFFF)));
  tearDownAll(() => white.dispose());

  MediaPosterData data({
    String title = 'Dune',
    bool withImage = true,
    String? caption = '2021 · 2h 35m',
    MediaKind kind = MediaKind.movie,
    MediaSeenState seen = MediaSeenState.none,
    double? rating = 7.8,
  }) => MediaPosterData(
    title: title,
    kind: kind,
    image: withImage ? TestImageProvider(white) : null,
    caption: caption,
    seen: seen,
    rating: rating,
  );

  Widget card(
    MediaPosterData data, {
    AppPalette palette = AppPalette.paper,
    double width = 110,
    MediaPosterVariant variant = MediaPosterVariant.captionOnImage,
    bool compact = false,
    bool? selected,
    Widget? action,
    VoidCallback? onTap,
    Locale locale = const Locale('en'),
  }) => testApp(
    SizedBox(
      width: width,
      child: MediaPosterCard(
        data: data,
        variant: variant,
        compact: compact,
        selected: selected,
        action: action,
        onTap: onTap,
      ),
    ),
    palette: palette,
    locale: locale,
  );

  int lineCount(WidgetTester tester, Finder text) {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );
    return paragraph
        .getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: paragraph.text.toPlainText().length,
          ),
        )
        .map((box) => box.top.round())
        .toSet()
        .length;
  }

  group('MediaPosterCard', () {
    test('should default to the variant applied in the mock-up (B)', () {
      expect(kDefaultPosterVariant, MediaPosterVariant.captionOnImage);
    });

    for (final palette in testPalettes) {
      final name = palette.id.name;

      testWidgets('should keep a 2:3 image on $name', (tester) async {
        await tester.pumpWidget(card(data(), palette: palette));

        final size = tester.getSize(find.byType(MediaPosterCard));
        expect(size.width, 110);
        expect(size.height, closeTo(165, 0.01));
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'should hide the title and veil the caption on an image on $name',
        (tester) async {
          await tester.pumpWidget(card(data(), palette: palette));

          expect(find.byKey(MediaPosterCard.titleKey), findsNothing);
          expect(find.byKey(MediaPosterCard.scrimKey), findsOneWidget);
          expect(find.text('2021 · 2h 35m'), findsOneWidget);
          final caption = tester.widget<Text>(
            find.byKey(MediaPosterCard.captionKey),
          );
          expect(caption.maxLines, 1);
          expect(caption.style?.color, MediaPosterCard.onImage);
        },
      );

      testWidgets(
        'should show a long title on at most 3 lines without image on $name',
        (tester) async {
          await tester.pumpWidget(
            card(data(title: _longTitle, withImage: false), palette: palette),
          );

          final title = find.byKey(MediaPosterCard.titleKey);
          expect(title, findsOneWidget);
          expect(tester.widget<Text>(title).maxLines, 3);
          expect(lineCount(tester, title), 3);
          expect(find.byKey(MediaPosterCard.scrimKey), findsNothing);

          final caption = find.byKey(MediaPosterCard.captionKey);
          expect(lineCount(tester, caption), 1);
          // Title and caption stay inside the poster.
          final poster = tester.getRect(find.byType(MediaPosterCard));
          expect(tester.getRect(title).top, greaterThan(poster.top));
          expect(
            tester.getRect(caption).bottom,
            lessThanOrEqualTo(poster.bottom),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('should keep text readable without image on $name', (
        tester,
      ) async {
        for (final kind in MediaKind.values) {
          await tester.pumpWidget(
            card(data(withImage: false, kind: kind), palette: palette),
          );
          final colors = palette.toExtension();
          final fill = kind.background(colors);
          final title = tester.widget<Text>(
            find.byKey(MediaPosterCard.titleKey),
          );
          final caption = tester.widget<Text>(
            find.byKey(MediaPosterCard.captionKey),
          );
          expect(
            contrastRatio(title.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: 'title on ${kind.name} fill',
          );
          expect(
            contrastRatio(caption.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: 'caption on ${kind.name} fill',
          );
        }
      });
    }

    testWidgets('should keep a long caption on one line', (tester) async {
      await tester.pumpWidget(
        card(data(caption: '2021 · 12 seasons and a very long runtime label')),
      );

      final caption = find.byKey(MediaPosterCard.captionKey);
      expect(lineCount(tester, caption), 1);
      expect(
        tester.getRect(caption).right,
        lessThanOrEqualTo(tester.getRect(find.byType(MediaPosterCard)).right),
      );
    });

    testWidgets('should keep the caption readable on a light image', (
      tester,
    ) async {
      // Width of a poster in a 3-column grid on a 360 dp phone.
      await tester.pumpWidget(card(data(), width: 109));

      final scrim = find.byKey(MediaPosterCard.scrimKey);
      final poster = tester.getRect(find.byType(MediaPosterCard));
      final scrimRect = tester.getRect(scrim);
      expect(scrimRect.bottom, poster.bottom);
      expect(
        scrimRect.height,
        closeTo(poster.height * MediaPosterCard.scrimHeightFactor, 0.01),
      );

      final gradient =
          (tester.widget<DecoratedBox>(scrim).decoration as BoxDecoration)
                  .gradient!
              as LinearGradient;
      expect(gradient.colors.last.a, closeTo(0.86, 0.001));

      // Worst case: a white image. The veil is lightest at the top of the
      // caption; even there the white text must reach AA.
      final captionRect = tester.getRect(
        find.byKey(MediaPosterCard.captionKey),
      );
      final t = (captionRect.top - scrimRect.top) / scrimRect.height;
      final veil = Color.lerp(gradient.colors.first, gradient.colors.last, t)!;
      final behindText = Color.alphaBlend(veil, const Color(0xFFFFFFFF));
      expect(
        contrastRatio(MediaPosterCard.onImage, behindText),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('should keep badges readable on a light image', (tester) async {
      final behindBadge = Color.alphaBlend(
        MediaPosterCard.badgeBackground,
        const Color(0xFFFFFFFF),
      );
      expect(MediaPosterCard.badgeBackground.a, closeTo(0.72, 0.005));
      expect(
        contrastRatio(MediaPosterCard.onImage, behindBadge),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('should drop caption and rating on a narrow poster', (
      tester,
    ) async {
      await tester.pumpWidget(card(data(), width: 77));

      expect(find.byKey(MediaPosterCard.captionKey), findsNothing);
      expect(find.byKey(MediaPosterCard.scrimKey), findsNothing);
      expect(find.text('7.8'), findsNothing);
      expect(find.byIcon(Icons.movie), findsOneWidget);
    });

    testWidgets('should expose title, type, caption and state to a reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        card(
          data(kind: MediaKind.series, seen: MediaSeenState.seen),
          onTap: () {},
          locale: const Locale('fr'),
        ),
      );

      expect(
        tester.getSemantics(find.byType(MediaPosterCard)),
        matchesSemantics(
          label: 'Dune, Série, 2021 · 2h 35m, Note 7.8, Vu',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('should show the seen check only when seen', (tester) async {
      await tester.pumpWidget(card(data()));
      expect(find.byIcon(Icons.check), findsNothing);

      await tester.pumpWidget(card(data(seen: MediaSeenState.seen)));
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.pumpWidget(card(data(seen: MediaSeenState.inProgress)));
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('should show a heart on a liked title', (tester) async {
      MediaPosterData liked() => const MediaPosterData(
        title: 'Dune',
        kind: MediaKind.movie,
        caption: '2021',
        liked: true,
      );
      await tester.pumpWidget(card(data()));
      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.pumpWidget(card(liked()));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Still shown when the poster is too narrow for the caption.
      await tester.pumpWidget(card(liked(), width: 77));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('2021'), findsNothing);
    });

    testWidgets('should call onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(card(data(), onTap: () => taps++));

      await tester.tap(find.byType(MediaPosterCard));
      expect(taps, 1);
    });

    testWidgets('should give its action a 48 dp target of its own', (
      tester,
    ) async {
      var posterTaps = 0;
      var actionTaps = 0;
      await tester.pumpWidget(
        card(
          data(),
          onTap: () => posterTaps++,
          action: IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => actionTaps++,
          ),
        ),
      );

      final action = tester.getRect(find.byType(IconButton));
      final poster = tester.getRect(find.byType(MediaPosterCard));
      expect(action.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(action.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(action.bottomRight, poster.bottomRight);
      // The caption stops before the action.
      expect(
        tester.getRect(find.byKey(MediaPosterCard.captionKey)).right,
        lessThanOrEqualTo(action.left),
      );

      await tester.tap(find.byType(IconButton));
      expect(actionTaps, 1);
      expect(posterTaps, 0);
    });

    testWidgets('should show the selection state in selection mode', (
      tester,
    ) async {
      await tester.pumpWidget(card(data(), selected: false));
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byIcon(Icons.movie), findsNothing);

      await tester.pumpWidget(card(data(), selected: true));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should draw a thumbnail without any text when compact', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(data(seen: MediaSeenState.seen), width: 50, compact: true),
      );
      expect(find.byType(Text), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(tester.getSize(find.byType(MediaPosterCard)), const Size(50, 75));

      await tester.pumpWidget(
        card(data(withImage: false), width: 50, compact: true),
      );
      expect(find.byType(Text), findsNothing);
      expect(find.byIcon(Icons.movie), findsOneWidget);
    });

    testWidgets('should draw a book as a cover with a spine', (tester) async {
      await tester.pumpWidget(
        card(data(kind: MediaKind.book, caption: '1965 · 612 p.')),
      );

      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(MediaPosterCard),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(
        clip.borderRadius,
        const BorderRadius.horizontal(
          left: Radius.circular(3),
          right: Radius.circular(8),
        ),
      );
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    group('caption below (variant C)', () {
      testWidgets('should leave the image bare and write underneath', (
        tester,
      ) async {
        await tester.pumpWidget(
          card(
            data(title: _longTitle),
            variant: MediaPosterVariant.captionBelow,
          ),
        );

        expect(find.byKey(MediaPosterCard.scrimKey), findsNothing);
        final title = find.byKey(MediaPosterCard.titleKey);
        expect(tester.widget<Text>(title).maxLines, 2);
        expect(lineCount(tester, title), 2);
        expect(lineCount(tester, find.byKey(MediaPosterCard.captionKey)), 1);
        // Image first (2:3), text below it.
        expect(
          tester.getRect(title).top,
          greaterThanOrEqualTo(
            tester.getRect(find.byType(MediaPosterCard)).top + 165,
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('should fit in the cells of its grid delegate', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                gridDelegate: MediaPosterCard.gridDelegate(
                  context: context,
                  width: constraints.maxWidth,
                  crossAxisCount: 3,
                  variant: MediaPosterVariant.captionBelow,
                ),
                itemCount: 3,
                itemBuilder: (context, index) => MediaPosterCard(
                  data: data(title: _longTitle),
                  variant: MediaPosterVariant.captionBelow,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          lineCount(tester, find.byKey(MediaPosterCard.titleKey).first),
          2,
        );
      });
    });

    testWidgets('should size grid cells to the poster in variant B', (
      tester,
    ) async {
      late SliverGridDelegateWithFixedCrossAxisCount delegate;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              delegate =
                  MediaPosterCard.gridDelegate(
                        context: context,
                        width: 320,
                        crossAxisCount: 3,
                      )
                      as SliverGridDelegateWithFixedCrossAxisCount;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(delegate.crossAxisCount, 3);
      expect(delegate.mainAxisExtent, closeTo(100 * 1.5, 0.001));
    });
  });
}
