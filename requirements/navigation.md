# Navigation (Home Row)

The application uses a persistent bottom navigation bar to provide quick access to the main functional areas. This "Home Row" is designed to be always visible while navigating the main sections of the app.

## Implementation Details
- **File**: `lib/features/search/presentation/pages/main_page.dart`
- **Widget**: `MainPage` (StatefulWidget)
- **Controller**: Uses `_selectedIndex` to manage the active tab.

## Tabs
1.  **Search (Discover)**: The default landing page where users can browse trending content or search for specific media.
2.  **My Lists (Saved Media)**: Displays the user's custom lists and bookmarked items.
3.  **Seen (History)**: Shows a history of media the user has marked as seen.
4.  **Alerts (Notifications)**: A center for upcoming releases and other user-relevant notifications.

## Key UI Components
- **BottomNavigationBar**: A persistent widget at the bottom of the screen. It uses `BottomNavigationBarType.fixed` to ensure all labels are visible.
- **Floating Action Button (FAB)**: Located at the end float position, this global button triggers the `SearchOverlay` regardless of which tab is active.
- **IndexedStack**: The core navigation container that maintains the state and scroll position of each tab's page when switching.

## Global Overlays
- **Achievement Notification**: A temporary banner that slides in from the top when an achievement is unlocked. It is designed to appear below the status bar but above the main content, ensuring it doesn't completely block navigation while remaining highly visible.
