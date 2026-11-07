/// Version shown in the About dialog.
///
/// Must equal the `X.Y.Z` part of `version:` in `pubspec.yaml`. release-please rewrites
/// the line below in each release PR (`extra-files` in `release-please-config.json`), and
/// `test/core/utils/app_version_test.dart` fails if the two drift apart.
const String appVersion = '1.1.0'; // x-release-please-version
