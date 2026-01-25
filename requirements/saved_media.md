# Saved Media (My Lists)

The Saved Media screen is the personal hub for user-curated content. It supports multiple lists, advanced sorting, and social sharing features.

## Implementation Details
- **File**: `lib/features/search/presentation/pages/saved_media_page.dart`
- **Key Features**: List management, custom sorting, QR sharing, and multiple display modes.

## Functional Areas

### List Management
- **Switch Lists**: Users can switch between their "Watchlist" (default) and custom user-created lists via a dropdown in the App Bar.
- **Create/Delete Lists**: Ability to create new collections or remove existing ones.
- **Edit Mode**: Long-pressing an item enters "Edit Mode," allowing for bulk deletion.

### Display Modes
Users can toggle between three distinct viewing experiences:
1.  **List View**: A traditional list with drag-and-drop manual reordering.
2.  **Grid View**: A visual poster grid with reorderable elements.
3.  **Swipe View**: A Tinder-like interface for focused, one-by-one browsing of the list.

### Sorting and Reordering
- **Manual Order**: The default mode, allowing users to drag items to their preferred positions.
- **Release Date**: Automatic sorting based on the media's original release.
- **Shuffle**: For those who can't decide what to watch next.
- **Reverse Toggle**: Inverts the current sorting logic.

### Sharing & Social
- **QR Sharing**: Generates a stylized QR code (featuring the app's mascot) that other users can scan to instantly import the entire list.
- **Deep Linking**: Shareable web links that open the app and trigger the import process.
- **QR Scanner**: Built-in scanner to receive lists from other users.

### Offline Resilience
- The screen provides basic functionality even without an internet connection, using locally cached previews (titles and poster paths) to populate the lists.
