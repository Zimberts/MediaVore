# Theming & Design System

MediaVore uses a robust, multi-theme architecture designed for high customization and consistency. A strict rule of the project is that **no colors should be hard-coded within the application widgets.**

## Implementation Details
- **Core File**: `lib/core/theme/app_palette.dart`
- **Provider**: `SettingsProvider` (manages current theme selection)
- **Extension**: `AppThemeExtension` (allows accessing custom semantic colors via `context.appColors`)

## Theming Architecture

### AppPalette
Each theme is defined as a class extending `AppPalette` (e.g., `SlatePalette`, `ParchmentPalette`, `MidnightPalette`). This abstract class defines semantic colors for every part of the application:
- **Surface Colors**: Backgrounds, cards, navigation bars, and dialogs.
- **Brand Colors**: Like hearts, rating stars, and "On Watchlist" indicators.
- **Semantic Badges**: Distinct colors for "Seen" vs. "Unseen" items.
- **Logic & Syntax Colors**: A unique design choice where functional elements are colored based on a "syntax highlighting" philosophy (Logic Flow, Data Values, Constants, Functions).

### AppThemeExtension
To ensure ease of use and prevent hard-coding, custom colors that don't fit into standard Material `ColorScheme` are exposed via a `ThemeExtension`. 
- **Usage**: Developers use `context.appColors.primaryBg` instead of `Colors.white`.
- **Consistency**: This ensures that when a user switches from "Default Light" to "Parchment," every single icon, border, and text element updates its color automatically.

## Themes Available
The app ships with multiple predefined palettes:
- **Light**: Default Light, Parchment, Mint, Solarized, Pinky.
- **Dark**: Default Dark, Slate, Midnight, Espresso.

## Extensibility
The design system is built to grow. If a new semantic color is required for a new feature:
1.  Add the color property to the `AppPalette` abstract class.
2.  Implement the color in all existing palette classes (e.g., `SlatePalette`, `DefaultLightPalette`, etc.).
3.  Add the property to `AppThemeExtension` and update its `copyWith` and `lerp` methods to ensure smooth transitions between themes.

## Hard-coding Policy
- **Prohibited**: `Colors.blue`, `Color(0xFF...)` within UI code.
- **Required**: Using `Theme.of(context).colorScheme` or `context.appColors` for all visual styling. This guarantees that the interface remains readable and aesthetically pleasing across all 9+ themes.
