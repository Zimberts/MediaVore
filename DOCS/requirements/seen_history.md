# Seen History & Logging

The Seen History and logging system provides a detailed record of everything the user has watched, allowing for precise tracking of dates, times, and multiple viewings.

## Implementation Details
- **Management Widget**: `lib/features/media_details/presentation/widgets/seen_manager.dart`
- **History Screen**: `lib/features/media_details/presentation/pages/seen_history_page.dart`
- **Database Entity**: `SeenItem` (persisted in local storage)

## Viewing History Screen Features

### Organization
- **Smart Grouping**: In history mode, items are grouped under date headers (e.g., "Monday, October 14, 2024").
- **Media Thumbnails**: Each entry displays the poster, title, and release info.
- **Indicators**: Visual icons show whether an item is "Liked" and its length (runtime or season count).

### Management
- **Library vs. History**: Switch between a chronological log of all viewing events or a grouped library of unique titles.
- **Deletion**: Swipe-to-delete entries with a confirmation pop-up to avoid accidental removals.

## The Logging Process (`SeenManager`)

### Interface
- **Check-Circle Button**: A primary action button used throughout the app (Media Details, Search Grid, etc.).
- **Visual State**: Changes from an outline icon to a filled "success" icon once an item is marked seen.

### Date/Time Selection Pop-up
When marking an item as seen, a dedicated dialog appears:
- **Calendar View**: A visual calendar defaulted to the current date.
- **Time Selection**: Opens a secondary system-style time picker, defaulted to the current time.
- **Manual Text Entry**: Option to toggle from a calendar to a text field for fast date typing (DD/MM/YYYY).
- **Multiple Viewings**: Users can add multiple viewing dates for the same movie or episode by tapping the filled checkmark and selecting "Add New Viewing".

### Batch Actions
- **Clear History**: Long-pressing the seen status allows for a complete wipe of all viewing history for that specific title.
