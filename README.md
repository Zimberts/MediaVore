# MediaVore

An app to keep track of movies/series/books seen/read or to watch/to read

## Deep Linking Configuration

To enable shared links (`https://mediavore.app/share`) to open the app directly on Android without opening the browser first, you must host a configuration file on your domain.

### Android App Links
Host a file at: `https://mediavore.app/.well-known/assetlinks.json`

Content:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "fr.zimberts.mediavore",
      "sha256_cert_fingerprints": [
        "YOUR_APP_SHA256_FINGERPRINT"
      ]
    }
  }
]
```
Replace `YOUR_APP_SHA256_FINGERPRINT` with your actual release/debug certificate fingerprint.

## Participate

Use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)

\<type>(\<scope>): \<description>

The main types are `feat`, `fix`, `chore`, `bump`

The main scopes at the moment are `README`, `back`, `front`

## Product description

The aim of MediaVore is to record movies/series/books read/seen or which you want to.

At first the app will be stand alone (no server) but might evolve in the end.

For more details, the app will be split between books and movies/series (will start by the movies part, then series and will end with books).

### Movies/Series

- [ ] You'll have the possibility to fetch movies you want based on their name and year (at first).

- [ ] Then add them to your main watchlist (ordered by date added, but can be changed in front)

- [ ] Or add them to another Named list ordered by choice (not date added)

- [ ] Once you have seen them you enter manually with date seen, rating

- [ ] Possibility to import through csv

- [ ] get the platform where you can whatch it

- [ ] add a movie that is not published, send a notification / reminder when it'll be publish
  (same for series when a new episode gets out)

### Books

- [ ] Just like the movies and series, you have the possibility to record a book you have read or you want to read

Books data:

- Time of finish (if set as read)
- Rating on how you liked the book
- Number of the books (for series) (example 0 and number / -1 and 0 based number)

Additional features:

- [ ] (might add possibility to enter the time it took to read the book)
- [ ] Add a book by scanning its barcode

## Achievements

MediaVore includes a gamified achievement system to track your viewing habits and milestones. Check out the [Achievements documentation](ACHIEVEMENTS.md) for a full list of available badges.

## Key Features

### Notification Center
- **Releases Tab**: Track upcoming movie releases and TV episode air dates. Releases are sorted by air date, with unplanned/future releases grouped at the bottom. TV episodes older than 30 days are hidden from view to reduce clutter while remaining tracked for notifications.
- **Quick Add Tab**: Get AI-suggested next episodes for your favorite TV series based on your watch history. Easily add new series to track with a single tap.

### Data Management
- **Export/Import**: Full backup and restore of your media library including seen history, likes, notifications, quick add items, and custom lists. Supports three import modes: append, replace, and merge.
- **Auto-population**: Quick Add is automatically populated from your seen history after importing data, ensuring you don't lose tracking of your viewing streaks.

### Gamification
- **Achievements**: Unlock badges as you progress through your media journey. Track genre milestones, viewing streaks, runtime records, and more.

## Project Setup on a New Machine

If you have cloned this project on a new machine, you may encounter errors when trying to run it for the first time. This is often due to missing dependencies or stale auto-generated files that are specific to the previous development environment (like Windows).

Follow these steps in your terminal to set up the project correctly on your new machine (macOS):

1. **Check your Flutter environment:**
    Run this command to check that your Flutter installation is correct and that you have the necessary tools (like Xcode and Android Studio) to build the app.

    ```sh
    flutter doctor
    ```

2. **Get dependencies:**
    This command downloads all the project's dependencies and links them for your current platform.

    ```sh
    flutter pub get
    ```

3. **Regenerate auto-generated files:**
    Your project uses code generation. This command will delete old files and create new ones that are compatible with your current setup. This is a crucial step.

    ```sh
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

After completing these three steps, the project should build and run correctly.
