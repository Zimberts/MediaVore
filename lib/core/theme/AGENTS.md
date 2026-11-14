# theme/ — conventions

App theming: design tokens, palettes, fonts and the Material theme built from them.

## Key files

- `lib/core/theme/app_palette.dart` — `AppPaletteId`, `AppPalette` (tokens), `AppThemeExtension`
- `lib/core/theme/app_theme.dart` — `buildAppColorScheme` / `buildAppTheme`
- `lib/core/theme/app_typography.dart` — `AppFonts`, `buildAppTextTheme`
- `lib/core/theme/font_licenses.dart` — OFL texts on the licenses page
- `assets/fonts/` — bundled static fonts (see its `README.md`)

## Gotchas

- Token values come from the design prototype; `test/core/theme/app_palette_test.dart`
  pins them. A palette only changes `bg`, `surface`, `surface2`, `border`; the other
  tokens depend on the brightness alone.
- Consume tokens via `context.appColors` (`AppThemeExtension`), never ad-hoc `Color`s.
  Add a token to `AppPalette` + `AppThemeExtension` (fields, `copyWith`, `lerp`).
- The primary color is the ink (`text`): no seed, `ColorScheme` is written role by role.
- Media colors (`film`, `serie`, `livre`, `duo`) identify a media type only. States use
  `danger` / `onDanger`, `success`, `warning`.
- Outlines of state controls (unchecked box, switch off) use `stateOutline` (`text2`,
  3:1); `border` is decorative and does not reach 3:1.
- Any new token pair that carries text or state must be added to
  `test/core/theme/app_contrast_test.dart` (WCAG AA: 4.5:1 text, 3:1 non-text).
- Palettes are persisted by `AppPaletteId.name` (`lightPalette` / `darkPalette` prefs):
  never rename a value. Display names are localized (`paletteName` in `core/l10n`).
- Fonts are static files declared in `pubspec.yaml`; never add `google_fonts` or any
  runtime font download. Only use the bundled weights (Bricolage 500/700, Inter 400–700).

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
