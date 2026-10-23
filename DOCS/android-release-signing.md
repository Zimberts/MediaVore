# Android release signing

Release builds (`flutter build apk|appbundle --release`, `flutter run --release`) are signed
with the upload key. The key and its passwords are **never committed**: `android/key.properties`,
`*.jks` and `*.keystore` are gitignored.

If no credentials are found, any Gradle task of the `release` variant fails with an explicit
error instead of producing a debug-signed artifact. Debug and profile builds are unaffected.

## Local machine: `android/key.properties`

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

A relative `storeFile` is resolved against `android/app/`.

Create a key if you do not have one yet:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

## CI: environment variables

Used for any key missing from `key.properties`:

| Variable | Meaning |
| --- | --- |
| `MEDIAVORE_KEYSTORE_PATH` | path to the keystore file (absolute recommended) |
| `MEDIAVORE_KEYSTORE_PASSWORD` | keystore password |
| `MEDIAVORE_KEY_ALIAS` | key alias |
| `MEDIAVORE_KEY_PASSWORD` | key password |

GitHub Actions example: store the keystore base64-encoded in a secret and decode it before the build.

```yaml
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > "$RUNNER_TEMP/upload.jks"
- name: Build AAB
  run: flutter build appbundle --release
  env:
    MEDIAVORE_KEYSTORE_PATH: ${{ runner.temp }}/upload.jks
    MEDIAVORE_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
    MEDIAVORE_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
    MEDIAVORE_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
```

## Local-only escape hatch

To test a release build without the upload key (e.g. `flutter run --release`):

```bash
export ORG_GRADLE_PROJECT_mediavoreAllowDebugSigning=true
```

The artifact is then signed with the public debug key: never distribute it, never set this in CI.
