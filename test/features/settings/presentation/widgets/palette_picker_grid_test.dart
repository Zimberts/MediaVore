import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/settings/presentation/widgets/palette_picker_grid.dart';

void main() {
  Widget wrap(Widget child, {AppPalette palette = AppPalette.paper}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: palette.toThemeData(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('PaletteSwatchCard', () {
    testWidgets(
      'should render background, surface, and accent preview colors',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 140,
              height: 100,
              child: PaletteSwatchCard(
                palette: AppPalette.sand,
                name: 'Sand',
                selected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(PaletteSwatchCard),
            matching: find.byType(Material),
          ),
        );
        expect(material.color, AppPalette.sand.bg);

        final containers = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(PaletteSwatchCard),
                matching: find.byType(Container),
              ),
            )
            .toList();
        final boxColors = containers
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.color)
            .whereType<Color>()
            .toSet();
        expect(
          boxColors,
          containsAll([
            AppPalette.sand.surface,
            AppPalette.sand.surface2,
            AppPalette.sand.primary,
          ]),
        );
      },
    );

    testWidgets('should highlight selected card with border and check icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 100,
                child: PaletteSwatchCard(
                  key: const Key('selected_card'),
                  palette: AppPalette.night,
                  name: 'Night',
                  selected: true,
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: 140,
                height: 100,
                child: PaletteSwatchCard(
                  key: const Key('unselected_card'),
                  palette: AppPalette.ink,
                  name: 'Ink',
                  selected: false,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('selected_card')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('unselected_card')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsNothing,
      );

      final selectedMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const Key('selected_card')),
          matching: find.byType(Material),
        ),
      );
      final selectedShape = selectedMaterial.shape! as RoundedRectangleBorder;
      expect(selectedShape.side.color, AppPalette.night.primary);
      expect(selectedShape.side.width, 2.5);

      final unselectedMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const Key('unselected_card')),
          matching: find.byType(Material),
        ),
      );
      final unselectedShape =
          unselectedMaterial.shape! as RoundedRectangleBorder;
      expect(unselectedShape.side.color, AppPalette.ink.border);
      expect(unselectedShape.side.width, 1);
    });
  });

  group('PalettePickerGrid', () {
    testWidgets('should call onChanged when a palette card is tapped', (
      tester,
    ) async {
      AppPaletteId? picked;
      await tester.pumpWidget(
        wrap(
          PalettePickerGrid(
            label: 'Light Theme',
            gridKey: const Key('grid'),
            selected: AppPaletteId.paper,
            palettes: AppPalette.lightPalettes,
            onChanged: (id) => picked = id,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('settings_palette_mist')));
      await tester.pumpAndSettle();

      expect(picked, AppPaletteId.mist);
    });

    testWidgets('should dim and ignore taps when disabled', (tester) async {
      AppPaletteId? picked;
      await tester.pumpWidget(
        wrap(
          PalettePickerGrid(
            label: 'Light Theme',
            gridKey: const Key('grid'),
            selected: AppPaletteId.paper,
            palettes: AppPalette.lightPalettes,
            enabled: false,
            onChanged: (id) => picked = id,
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(PalettePickerGrid),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.45);

      await tester.tap(
        find.byKey(const Key('settings_palette_sand')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });
  });
}
