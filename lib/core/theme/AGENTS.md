# theme/ — conventions

App theming: color palettes and the `AppThemeExtension` theme extension.

## Key files

- `lib/core/theme/app_palette.dart`

## Gotchas

- `AppThemeExtension extends ThemeExtension` exposes semantic colors; consume via
  `context.appColors` (see the `appColors` extension defined here).
- Predefined light/dark palettes are registered in `lightThemes` / `darkThemes` lists.
- Add new semantic colors to `AppThemeExtension` + every palette, not ad-hoc `Color`s.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
