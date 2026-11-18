# home/ — conventions

Home tab ("Tonight") and the pages it opens. `presentation` only: the data comes from
`SearchProvider` (`inProgressItems`, `quickAddOptOuts`, `quickAddOmissions`, `notifiedItems`).

## Key files

- `presentation/pages/home_page.dart` — the tab: Resume, To watch tonight, Also in
  progress, paused row, Upcoming.
- `presentation/pages/in_progress_page.dart` — `InProgressPage`, full list behind
  "See all" (open it with `InProgressPage.show`).
- `presentation/pages/upcoming_page.dart` — `UpcomingPage`, every followed release:
  already released, month by month, without a date; `HiddenReleasesDebugSection`.
- `presentation/upcoming_actions.dart`, `widgets/upcoming_row.dart`,
  `widgets/upcoming_rows_card.dart` — rows and actions of a release (open, mark as seen,
  disable the alert), shared by Home and `UpcomingPage`.
- `presentation/providers/home_session_provider.dart` — filters and sort of those pages,
  kept for the session (registered in `main.dart`).
- `presentation/in_progress_actions.dart` — mark as seen, open, remove from Quick Add:
  shared by Home and `InProgressPage`, each reports through `showAppMessage` + Undo.
- `presentation/in_progress_sort.dart`, `home_formatters.dart` — pure helpers (tested).
- `presentation/widgets/debug_omissions_section.dart` — debug block "hidden items grouped
  by reason", shown at the bottom of a list only with `SettingsProvider.notificationCenterDebug`.

## Gotchas

- "In progress" = the Quick Add queue (`InProgressService`), series only until books
  land (#325): kind chips are hidden while a single kind is present.
- "Paused" = no viewing for more than `InProgressItem.pauseAfter` (30 days).
- An opt-out of Quick Add is stored per episode (`QuickAddOptOutModel`). "Restore" clears
  it and recomputes the next episode (`SearchProvider.restoreQuickAddOptOut`). Opt-outs
  whose series is in progress again are not listed.
- "Upcoming" = `filterReleases` (what is hidden, and why) then `groupReleases`
  (`core/utils/release_groups.dart`: periods are rolling windows of 7 and 31 days on local
  calendar days). Home and the page must use both, so their counters agree; the counter
  of the title is the number of dated releases, whatever the type filter.
- Releases already out and not seen stay listed ("Already released"); an episode aired
  more than 30 days ago is hidden. Books have no release source: no "Books" chip.
- The former Alerts screen (`NotificationCenterPage`) is gone: its two tabs are
  `UpcomingPage` and `InProgressPage`.
- Never change how Quick Add is computed from here (`QuickAddService`).
- Pass the clock (`clock` parameter) instead of calling `DateTime.now()` in widgets.

Parent: [`lib/AGENTS.md`](../../AGENTS.md) · Root: [`AGENTS.md`](../../../AGENTS.md)
