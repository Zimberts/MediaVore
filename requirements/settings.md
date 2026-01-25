# Settings

The Settings screen allows users to customize their experience and manage their data. It is designed to be highly accessible and organized by functional areas.

## Implementation Details
- **File**: `lib/features/settings/presentation/pages/settings_page.dart`
- **Provider**: `SettingsProvider`
- **Accessibility**: A settings icon is present in the `AppBar` of almost every main functional page (Discovery, Seen History, Saved Media), allowing users to adjust preferences without returning to a home menu.

## Functional Sections

### Appearance
- **Theme Mode**: Choose between System, Light, and Dark modes.
- **Theme Selection**: Specific color palette selection for both Light and Dark themes.

### Gaming & Milestones
- **Achievements**: Access the full achievement collection and progress tracking.

### Lists Display
- **Privacy/Utility**: Toggle to hide non-released media from search results and lists.

### Storage & Data (Power User Sub-screen)
Located in `lib/features/settings/presentation/pages/data_cache_settings_page.dart`, this section provides advanced tools:
- **Cache Management**: Clear image cache to free up space.
- **Database Portability**: Tools to Export and Import the entire viewing history as a JSON file, intended for backup or migration between devices.
