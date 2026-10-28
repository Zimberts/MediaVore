# Releasing

Releases are cut by [release-please](https://github.com/googleapis/release-please) from the
Conventional Commits on `main` (decision A of #237, epic #244). Nobody edits the version or
pushes a tag by hand.

## How a release happens

1. Every merge to `main` runs `.github/workflows/release.yml`: first `ci.yml` (analyze + test),
   then release-please. A red `main` never produces a release PR update, a tag or a build.
2. release-please opens or updates **one** PR, `chore(release): vX.Y.Z`, which edits
   `pubspec.yaml` (`version:`), `CHANGELOG.md` and `.release-please-manifest.json`.
   The next version comes from the commits since the last release:

   | Commit on `main` (= squashed PR title) | Bump |
   | --- | --- |
   | `fix:`, `perf:` | patch `1.1.0 → 1.1.1` |
   | `feat:` | minor `1.1.0 → 1.2.0` |
   | `feat!:` or footer `BREAKING CHANGE:` | major `1.1.0 → 2.0.0` |
   | `chore`, `ci`, `docs`, `refactor`, `test`, `build`, `style` | none on their own (hidden from the changelog) |

   A commit footer `Release-As: 1.3.0` forces a version. A non-conforming commit is ignored.
   The `bump` type is obsolete: only the release PR changes the version.
3. **To release, merge the release PR** (squash). The run on that merge creates the tag `vX.Y.Z`
   and the GitHub release (notes = the changelog section), then builds the Android APK and AAB
   from the tag in the same workflow.

Config: `release-please-config.json` (release type `dart`, tags `vX.Y.Z` without component,
changelog sections) and `.release-please-manifest.json` (current version, bootstrapped at
`1.1.0`). `bootstrap-sha` only bounds the first changelog when no `v1.1.0` GitHub release is
found; it is ignored afterwards.

## Version and build number (#236)

- `pubspec.yaml` `version: X.Y.Z+N`: `X.Y.Z` is owned by release-please. Before building a tag,
  CI runs `tool/check_release_version.sh vX.Y.Z` and fails if `X.Y.Z` differs from the tag.
- The `+N` in `pubspec.yaml` is **not** used for builds (release-please increments it, which is
  harmless). CI passes `--build-number ${{ github.run_number }}`: it grows with every run of
  `release.yml`, so two runs never share a build number (Android `versionCode`, iOS
  `CFBundleVersion`). A re-run of the same run keeps its number, which is fine since it rebuilds
  the same commit; a store will reject a second upload of that number.
- `run_number` restarts at 1 for a new workflow file (`release.yml` replaced `android-build.yml`).
  If a store already holds a higher build number, add a fixed offset in the build step.

## Android artifacts (#238)

The `android` job of `release.yml` builds, with the upload key (`DOCS/android-release-signing.md`)
and the same build number:

- `app-release.apk` (direct download from the GitHub release) and `app-release.aab` (Play Store);
- `app-release.apk.sha256` and `app-release.aab.sha256` (`sha256sum` format with bare file names:
  check a download with `sha256sum -c app-release.apk.sha256`); the hashes are also printed in
  the run summary.

They are uploaded as the workflow artifact `mediavore-android-release` (7 days), which later jobs
of the same run attach to the release. Before that, `tool/check_16kb_alignment.sh` fails the job
unless the artifacts support 16 KB memory pages (Android 15+, required by Google Play): every
`LOAD` segment of the 64-bit native libraries (`arm64-v8a`, `x86_64`) has an alignment ≥ 16 KB,
and, for the APK, `zipalign -c -P 16` passes (uncompressed libraries start on a 16 KB boundary).
Run it locally on a build with `tool/check_16kb_alignment.sh build/app/outputs/flutter-apk/app-release.apk`
(needs `readelf`, `unzip`, and `ANDROID_HOME` with build-tools ≥ 35, or `ZIPALIGN=/path/to/zipalign`).

## Manual test build

*Actions → Release → Run workflow* on any branch or tag: runs analyze/test then builds the APK
and AAB (artifact `mediavore-android-release`), without release-please. On a tag ref the pubspec/tag check
runs too.

## One-time setup (repository admin)

1. **Token for release-please.** With the default `GITHUB_TOKEN`, the release PR triggers no
   workflow, so its required checks (CI, PR title) never run and it cannot be merged without
   bypassing protection. Create one of:
   - a **fine-grained PAT** on `Zimberts/MediaVore` with *Contents: read and write*,
     *Pull requests: read and write*, *Issues: read and write*, stored as the Actions secret
     `RELEASE_PLEASE_TOKEN` (expires: renew it);
   - or a **GitHub App** with the same permissions, installed on the repo; then replace the
     token line in `release.yml` with an `actions/create-github-app-token` step (secrets
     `RELEASE_APP_ID`, `RELEASE_APP_PRIVATE_KEY`). Preferred for an organization: not tied to
     a person, no expiry.

   Without the secret the workflow still works and warns; the release PR then needs its
   checks run by hand (e.g. close/reopen it, or push an empty commit to its branch).
2. *Settings → Actions → General → Workflow permissions*: allow GitHub Actions to create and
   approve pull requests (needed only for the `GITHUB_TOKEN` fallback).
3. *Settings → General → Pull Requests*: allow **squash merging only**, default message
   = PR title, so the PR title (checked by CI) is the commit release-please reads.
4. Android signing secrets: `DOCS/android-release-signing.md`.
