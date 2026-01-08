# MediaVore Project Roadmap

## 🎨 Theming System
### Phase 1: Infrastructure
- [x] **Semantic Color Mapping**: Define a `ThemePalette` interface/abstract class to map hex codes to semantic names (e.g., `primaryBg`, `surface`, `statusAccent`).
- [ ] **Centralized Color Management**: Refactor existing widgets to consume colors from the palette rather than hardcoded values.
- [x] **Settings Integration**: Update `SettingsProvider` to include `themeMode` (light, dark, system) and specific theme selections.

### Phase 2: Features & Variety
- [ ] **Theme Selection UI**: Implement a e Settings page to switch between available themes.
- [ ] **Adaptive Mode**: Support independent selection of which Light and Dark themes are used when "Match System" is active.
- [ ] **Initial Themes**:
    - [ ] Default Material 3 (Deep Purple seed).
    - [ ] **Slate**: The classic "stony" dark theme (see reference below).
    - [ ] (Optional) Obsidian Slate & Copper Slate variations.

---

## 📖 Reference: Slate Theme DNA
The Slate theme is a classic "stony" dark theme. It avoids high-contrast pure blacks and neon colors, opting instead for a palette of muted earth tones.

### Core Philosophy
- **Background**: Warm charcoal (#262626).
- **Primary Text**: Pure white (#ffffff).
- **UI Elements**: Status bars/menus use "Muted Olive" (#afaf87) for a distinct visual break.

### Color Palette (HEX)
| Group | Role | Hex Code |
| :--- | :--- | :--- |
| **Backgrounds** | Main Background | `#262626` |
| | Selection Highlight | `#333333` |
| **UI Accents** | Status/Menus | `#afaf87` |
| | Visual Selection | `#5f8700` |
| **Syntax/Data** | Keywords/Logic | `#5f87d7` |
| | Strings/Values | `#87d7ff` |
| | Constants | `#ffafaf` |
| | Functions | `#ffd7af` |
| | Structural Labels | `#ffd700` |

### Implementation Mapping
When building the palette, map colors to these functional groups:
- **Neutral Base**: Low-saturation dark grey.
- **Logic/Flow**: Most prominent cool color (Blue/Teal).
- **Data/Values**: Brightest accent (Sky Blue).
- **Structural**: Warm "warning" color (Gold/Orange).
- **Comments**: Maintain a ~3:1 contrast ratio to the background (`#666666`).
