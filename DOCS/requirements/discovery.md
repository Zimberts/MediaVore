# Discovery / Search Screen

The Discovery screen is the primary portal for exploring media content. It combines high-level browsing with powerful filtering tools and a global search interface.

## Implementation Details

- **File**: `lib/features/discovery/presentation/pages/discovery_page.dart`
- **Global Search**: `lib/features/search/presentation/widgets/search_overlay.dart`
- **Provider**: `SearchProvider` (handles API calls, pagination, and search state)

## Features

### Discovery Grid

- **Visual Browsing**: Media is presented in a responsive grid of posters.
- **Dynamic Grid Size**: Users can adjust the number of columns in the grid (2-5) via a slider to suit their visual preference.
- **Lazy Loading**: Implements infinite scrolling, fetching more content from TMDB as the user nears the bottom of the list.
- **Status Indicators**: Overlays on posters indicate if an item has been seen, is partially watched, or completed.
- **Interaction**: Tapping any element in the grid opens the **Media Details** view.

### Search Functionality

- **Discovery Search**: A search bar within the Discovery tab allows users to filter the currently loaded list by title.
- **Global Search Overlay**:
  - Accessed via the persistent FAB (Floating Action Button) on the `MainPage`.
  - **Debounced Input**: Search requests are delayed by 500ms to avoid excessive API calls while typing.
  - **Clear and Reset**: Clicking the 'X' or clear button empties the search input. When the input is cleared, the search results are removed and replaced by the original discovery content.
  - **Direct Navigation**: Tapping a search result immediately opens the `MediaDetailPage`.
- **List Interaction**: Resulting items in the search overlay or discovery grid can be directly added to the user's **Watchlist** via a **bookmark** icon button.

### Interface Elements

- **Settings Access**: A settings icon is present in the `AppBar` for quick configuration.
- **Grid Controls**: Buttons to adjust grid size and open the filter dialog are located in the `AppBar`.

### Filtering Tools

- **Filter Dialog**: Advanced users can filter the discovery list by:
  - Media Type (Movies vs. TV Shows)
  - Release Year
  - Minimum Rating
  - Genres (dynamically updated based on the selected media type)

<!-- All discovery requirements are expected to be covered by tests in the test suite. If you need explicit mapping to test files, run the test coverage report. -->
