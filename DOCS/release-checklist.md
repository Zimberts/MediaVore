# Manual release checklist

Run before merging the release PR `chore(release): vX.Y.Z` (see `DOCS/releasing.md`), then tick
the box at the bottom of that PR. About 15 minutes on a real Android phone, and on an iPhone when
one is available. It covers what the automated tests cannot: real TMDB data, the camera, the
background sync, an upgrade over an existing install, and iOS (no iOS CI).

If a step fails, open a `fix:` issue labelled with the release, link it from the release PR, and
do not merge until it is fixed or explicitly deferred.

## Setup

- Phone A: the **previous** release installed from its GitHub release APK, with real data (seen
  movies and episodes, a few lists, at least one series in *Upcoming*) and a TMDB key.
- Phone B (step 7 and 8): any phone with MediaVore installed, ideally the new build.
- The new APK: *Actions → Release → Run workflow* on the release PR branch (artifact
  `mediavore-android-release`). Same upload key as the GitHub releases, so it installs over them.
- A TMDB API key (v3) or read access token (v4).

## Checks

Write the result next to each line in the release PR if anything is unusual.

### Upgrade and first launch

1. **Upgrade keeps data.** On phone A, install the new APK over the previous one
   (`adb install -r app-release.apk`, or open the APK). The app starts without the startup error
   screen; seen counts in *Me*, lists in *Library*, history and *Upcoming* are unchanged.
   *Me → Settings → About* shows the new version.
2. **Fresh install.** Uninstall, reinstall, launch: the TMDB key page opens. A wrong key is
   rejected; *Skip for now* reaches the app; the real key is verified and saved from
   *Me → TMDB API Credential*. (Then restore phone A's data with step 8's import, or reinstall the
   previous release first and do step 1 last.)

### Real TMDB data

3. **Search and detail.** *Discover*: search a movie, a series and a person. Open a movie and a
   series: poster, synopsis, cast, related titles load. *Where to watch* lists offers for the
   country chosen in *Settings → Platforms country*.
4. **Quick journeys.** From a detail page: add to the watchlist, mark a movie as seen, mark an
   episode then a whole season of a series as seen. The title appears in *Library* and in *Home*
   (in progress / history) without restarting the app.
5. **Swipe.** Enable *Settings → Swipe mode in Discover* if needed, then in *Discover*: add a few titles, discard a few, undo once. A saga card
   shows its badge. Added titles are in the chosen list.
6. **Offline.** Airplane mode: already-opened pages still show their cached data, a new search
   shows an error instead of hanging; back online, retry works.

### Two phones

7. **Together.** Phone A shows its QR code (*Together*), phone B scans it with the camera (grant
   the permission when asked; a list too large for one QR is scanned part by part). *See common
   titles* lists the intersection; *Vote by swiping* goes through each participant's turn and
   ends on *Tonight's choice*.
8. **Export / import.** Phone A: *Me → Storage & Data → Export All Data*, share the `.mdv`
   file to phone B. Phone B: *Import All Data*, check the preview counts, import (merge). Seen,
   likes, alerts and lists match phone A.

### Background sync

9. **Daily sync runs.** The sync refreshes returning series and the *Upcoming* alerts (the app
   sends no system notification). With phone A plugged in and USB debugging on:

   ```sh
   adb logcat -c
   adb shell dumpsys jobscheduler | grep -A3 fr.zimberts.mediavore   # note the job id (#u0aNN/<id>)
   adb shell cmd jobscheduler run -f fr.zimberts.mediavore <id>
   adb logcat -d | grep -E "daily background sync|Background"
   ```

   Expect `Running daily background sync...` and no `Background Task Failed`. Then open
   *Home → Upcoming*: the list still loads and matches the series followed.

### Display and languages

10. **Themes.** *Settings → Theme Mode*: light, dark, system; switch a palette in each. Home,
    a detail page and *Together* stay readable (no invisible text or icons).
11. **Languages.** *Settings → Language*: French then English. Tabs, settings and a detail page
    switch language, including TMDB texts (synopsis) after a refresh.
12. **Large font.** Android *Display → Font size* at maximum: Home, a detail page, the tab bar and
    the swipe cards have no overflow stripes or clipped buttons. Reset the font size afterwards.

### iOS (when an iPhone is available)

13. **iOS build.** Build and install from the release tag as described in `DOCS/ios-release.md`
    (*Local build*), or from TestFlight if the `ios` job uploaded it. Run steps 2, 3, 4 and 7
    (camera permission prompt included).
14. **iOS background.** In Xcode, with the app running from the debugger, *Debug → Simulate
    Background Fetch*: the console shows `Running daily background sync...`.

### Done

15. **Record.** Tick *Manual checklist done* in the release PR footer and add a PR comment with
    the phones (model, Android/iOS version) and any skipped step with its reason. release-please
    rewrites the PR body (and unticks the box) whenever a new commit lands on `main`: the box
    then means the pass must be redone on the new build.
