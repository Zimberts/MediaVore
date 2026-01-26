# Notification Center

The Notification Center is a hub for staying up-to-date with upcoming releases and quickly managing viewing progress for ongoing TV series.

## Implementation Details
- **File**: `lib/features/media_details/presentation/pages/notification_center_page.dart`
- **Tabs**: `Releases` and `Quick Add`.

## Functional Tabs

### Releases Tab
- **Upcoming Media**: Shows a chronological list of movies and TV episodes the user has "notified" (subscribed to).
- **Time Window**: Displays content released within the last 30 days or scheduled for the future.
- **Smart Filtering**: Items are automatically removed from this list once they are marked as seen.
- **Direct Actions**:
  - **Mark as Seen**: Quickly log a movie or a specific notified episode as watched directly from the list.
  - **Unsubscribe**: Remove the item from notifications.

### Quick Add Tab
- **Next Episode Tracking**: Automatically identifies the next unwatched episode for every TV series in the user's history.
- **Viewing Shortcut**: Provides a one-tap "Mark as Seen" button for the next episode in the sequence, making it easy to keep history up-to-date without navigating to the media details page.
- **Series Discovery**: Tapping any series in the list opens its `MediaDetailPage` for full season browsing.

## Refresh and Sync
- **Force Refresh**: Allows users to manually trigger a network sync to update release dates and check for new episode availability.
- **Background Sync**: The app periodically updates notification data to ensure release dates remain accurate.
