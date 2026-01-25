# Media Details & Actor Profiles

The Media Details and Actor Detail screens provide deep dives into titles and the people behind them, creating an interconnected browsing experience.

## Implementation Details
- **Media Details File**: `lib/features/media_details/presentation/pages/media_detail_page.dart`
- **Actor Details File**: `lib/features/media_details/presentation/pages/actor_detail_page.dart`

## Media Details Layout

### Hero & Information
- **Visuals**: A large poster backdrop anchors the page.
- **Actions**: Global actions like "Like", "Notifications", and "History Export" are accessible in the app bar.
- **TV Tracking**: Dedicated progress bars and "Watch Next" suggestions for series.
- **Seasons**: Expandable list of seasons with individual episode tracking.

### Content Discovery
- **Trailers**: Inline YouTube player integration for trailers.
- **Cast List**: A horizontal gallery of actors. Tapping an actor navigates to the `ActorDetailPage`.
- **Related Media**: Recommendations and similar titles to keep discovery going.

## Actor Details Layout

The Actor Details screen is reached by tapping any actor in a media cast list.

### Profile Section
- **Portrait**: A large profile image of the actor.
- **Personal Info**: Key details like birthday and birthplace are displayed with clear iconography.
- **Biography**: A scrollable biography section.

### Filmography ("Known For")
- **Visual Grid**: A horizontal list of media items the actor is most famous for.
- **Interconnectivity**: Tapping any of these titles opens its corresponding `MediaDetailPage`, allowing users to jump back and forth between actors and their works.
