# Achievements

The Achievements system gamifies the user's media tracking experience by rewarding milestones and specific behaviors.

## Implementation Details
- **File**: `lib/features/achievements/presentation/pages/achievements_page.dart`
- **Global Page**: Accessible through the **Settings** menu.
- **Provider**: `AchievementProvider`

## Achievement Collection Interface
- **Visual Presentation**: Each achievement is presented in a list card featuring:
  - **Icon**: A custom star icon (or placeholder) that remains dimmed until unlocked.
  - **Information**: A "Cute Name" (title) and a clear description of the task.
  - **Progress Bar**: For unfulfilled multi-step achievements (e.g., "Watch 10 Drama movies"), a progress bar indicates current completion.
  - **Completion Date**: Once unlocked, the card displays the exact date the challenge was completed.

## Real-time Notifications (Achievement Pop-up)
When an achievement is unlocked during app usage, a global notification appears:
- **Design**: A temporary banner that slides in at the top of the screen for 4-5 seconds. It is positioned carefully so as not to cover the top navigation elements.
- **Content**: Displays the achievement title and a brief description.
- **Interactions**:
  - **Close Button**: A small 'X' to manually dismiss the pop-up.
  - **Deep Link**: Tapping anywhere else on the pop-up dismisses it and immediately navigates the user to the `AchievementsPage`, highlighting the newly earned badge.
