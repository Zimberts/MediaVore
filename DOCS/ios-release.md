# iOS release (App Store Connect / TestFlight)

Bundle id `fr.zimberts.mediavore`, team `E5L7NC8M9T`, iOS 15.0+. The Xcode project uses
**automatic signing**; CI switches to manual signing (see [CI](#ci)).

## One-time account setup (manual, Apple Developer account holder)

Done in the Apple web consoles, not in this repo. Needs the *Account Holder* or *Admin* role.

1. **App ID**: [Certificates, IDs & Profiles → Identifiers](https://developer.apple.com/account/resources/identifiers/list),
   register `fr.zimberts.mediavore` (explicit App ID). Capabilities: none beyond the
   defaults (background fetch/processing are Info.plist modes, not capabilities). Xcode
   automatic signing can also create it on the first archive.
2. **App record**: [App Store Connect → Apps → +](https://appstoreconnect.apple.com/apps) → *New App*:
   platform iOS, name `MediaVore`, primary language, bundle id `fr.zimberts.mediavore`, SKU
   (e.g. `mediavore`). TestFlight uploads are rejected until this record exists.
3. **App Store Connect API key** (used by CI to upload):
   [Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
   → *Team Keys* → generate, role **App Manager**. Note the *Key ID* and *Issuer ID*,
   download `AuthKey_<KEY_ID>.p8` (downloadable **once**). Store as repository secrets
   (*Settings → Secrets and variables → Actions*, repo admin):

   | Secret | Value |
   | --- | --- |
   | `ASC_KEY_ID` | Key ID (10 characters) |
   | `ASC_ISSUER_ID` | Issuer ID (UUID) |
   | `ASC_PRIVATE_KEY` | full contents of the `.p8` file, `-----BEGIN PRIVATE KEY-----` included |

   Then delete the local `.p8` or keep it in a password manager; never commit it.
4. **Export compliance**: `Info.plist` sets `ITSAppUsesNonExemptEncryption = false` (the
   app only uses encryption provided by the OS: HTTPS, Keychain), so TestFlight does not
   ask the question for each build.
5. **App Privacy** questionnaire in App Store Connect (required before App Store
   submission, not for TestFlight): data stays on the device; network calls go to TMDB with
   the user's own API key.

## Local build

Requires macOS, Xcode signed in (*Settings → Accounts*) with an Apple ID of team
`E5L7NC8M9T`, and CocoaPods.

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Output: `build/ios/ipa/*.ipa` (+ `build/ios/archive/Runner.xcarchive`). Xcode creates the
Apple Distribution certificate and the App Store profile on demand. Upload manually with
Transporter or:

```bash
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"   # .p8 in ~/.appstoreconnect/private_keys/
```

The version comes from `pubspec.yaml` (`CFBundleShortVersionString`) and the build number
from `--build-number` (`CFBundleVersion`). App Store Connect rejects a build number that was
already uploaded for the same version; `ExportOptions.plist` sets
`manageAppVersionAndBuildNumber = false` so Xcode does not rewrite it.

## `ios/ExportOptions.plist`

| Key | Value | Why |
| --- | --- | --- |
| `method` | `app-store-connect` | App Store / TestFlight distribution (`app-store` before Xcode 15.3) |
| `destination` | `export` | write the `.ipa`; upload is a separate step |
| `teamID` | `E5L7NC8M9T` | |
| `signingStyle` | `automatic` | local builds; CI overrides it |
| `manageAppVersionAndBuildNumber` | `false` | keep the Flutter build number |
| `uploadSymbols` | `true` | crash symbolication in App Store Connect |

## App Store upload checks covered here

- No alpha channel in app icons (`ITMS-90717`): icons are RGB, and `flutter_launcher_icons`
  has `remove_alpha_ios: true` so regenerating them keeps it that way.
- Purpose strings present for every protected API linked by plugins (`ITMS-90683`):
  camera (`mobile_scanner`, QR code of a shared list), photo library read (`file_picker`)
  and add (`share_plus`).
- `BGTaskSchedulerPermittedIdentifiers` lists `fr.zimberts.mediavore.dailySync`, required by
  the `processing` background mode (`workmanager`).

## CI

The `ios` job of `.github/workflows/release.yml` (#241) runs after analyze/test, on the run
that creates a release tag (and on *Run workflow*, see `DOCS/releasing.md`). It:

1. imports the Apple Distribution certificate into a temporary keychain and installs the App
   Store profile; `tool/ios_signing.py check-profile` fails the job early if the profile is not
   an App Store profile for `fr.zimberts.mediavore`, is expired, or does not contain the
   certificate (warning 30 days before expiry);
2. switches the `Runner` target's Release configuration to manual signing
   (`tool/ios_manual_signing.rb`, CI only) and copies `ios/ExportOptions.plist` with
   `signingStyle = manual`, `signingCertificate` and `provisioningProfiles` overridden
   (`tool/ios_signing.py export-options`); CI has no Apple ID for automatic signing;
3. runs `flutter build ipa --release --build-number <run_number>`, publishes the IPA and its
   SHA-256 as the artifact `mediavore-ios-release` (7 days, for a manual re-upload with
   Transporter), and uploads it with `xcrun altool` and the `ASC_*` key;
4. deletes the keychain, profile and API key, even on failure.

The runner must have an Xcode recent enough for App Store Connect (`MIN_XCODE_MAJOR` in the
job; Apple raises the minimum SDK every spring): bump `runs-on` when the check fails.

### Signing secrets (repository admin, once a year)

| Secret | Value |
| --- | --- |
| `IOS_DIST_CERT_P12_BASE64` | Apple Distribution certificate + private key, `.p12`, base64 |
| `IOS_DIST_CERT_PASSWORD` | password of that `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store profile (`.mobileprovision`), base64 |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY` | API key, see step 3 above |

1. **Certificate**: Xcode → *Settings → Accounts* → team `E5L7NC8M9T` → *Manage Certificates*
   → *+* → *Apple Distribution* (or reuse the existing one; a team has at most 3). In
   *Keychain Access → My Certificates*, right-click *Apple Distribution: …* (with its key) →
   *Export* → `.p12` with a strong password.
2. **Profile**: [Profiles → +](https://developer.apple.com/account/resources/profiles/add) →
   *Distribution / App Store Connect* → App ID `fr.zimberts.mediavore` → that certificate →
   name e.g. `MediaVore App Store` → download the `.mobileprovision`.
3. **Store them** (on a Mac, with `gh` logged in as a repo admin; checks everything locally,
   with the same checks as CI, before writing anything):

   ```bash
   tool/setup_ios_signing_secrets.sh dist.p12 MediaVore_App_Store.mobileprovision \
     AuthKey_XXXXXXXXXX.p8 <issuer-id>
   ```

4. Test with *Actions → Release → Run workflow* (`testflight` unchecked: build and signing
   only), then once with `testflight` checked.

The profile expires after one year and the certificate after one year as well: regenerate the
profile (and the certificate if needed) and run the script again. Never commit these files.

### Build number

TestFlight rejects a build number already uploaded for the same version. The number is the
`release.yml` run number, shared with Android; if App Store Connect already holds builds with
a higher number for the current version, add an offset in the *Build IPA* step.
