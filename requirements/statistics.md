# Media Statistics

The Media Statistics screen provides visual and data-driven insights into the user's viewing habits over time. It transforms the raw seen history into meaningful metrics.

## Implementation Details
- **File**: `lib/features/media_details/presentation/pages/media_stats_page.dart`
- **Charts**: Built using the `fl_chart` library.

## Core Metrics
Users can toggle between two primary metrics for all statistical views:
- **Entries (Logs)**: Counts the number of times media was marked as seen (e.g., number of episodes or movies).
- **Runtime (Time)**: Calculates the total time spent watching media in hours and minutes.

## Features

### Time Scoping
Statistics can be filtered by three different time scopes:
- **All Time**: A high-level overview of the entire history.
- **Yearly**: Focus on a specific year (selectable from a list).
- **Monthly**: A calendar-based selector allowing users to drill down into specific months of any given year.

### Overview Tab
- **Total Watch Time**: A prominent summary showing cumulative time spent in days, hours, and minutes.
- **Media Summary**: Quick counts of total movies vs. total episodes watched.
- **Hall of Fame**: Identifies the "Most Watched" movie, series, and specific episode within the selected time scope and metric.
- **Activity Chart**: A dynamic bar chart showing viewing activity (logs or minutes) over time (by month or by day depending on scope).

### Distribution Tab
- **Media Split**: A pie chart showing the percentage breakdown between Movies and TV Shows.
- **Top Genres**: A ranked list with progress bars showing the most-watched genres (Action, Drama, Sci-Fi, etc.), allowing users to see which categories dominate their consumption.
