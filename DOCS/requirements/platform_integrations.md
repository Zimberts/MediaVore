# Platform Integrations Requirements

Purpose: describe required integrations with platform features and native code.

- **App links & intents**: Android App Links and iOS Universal Links must open the app to corresponding screens.
- **Home widget**: If a home widget is provided, define required refresh intervals and tap actions that deep-link into the app.
- **Platform channels**: Native modules used (e.g., file picker, notifications, sensors) must have clear fallbacks and permission checks.
- **Permissions**: Request only required permissions at the time of use; document privacy implications.
- **Background tasks**: Scheduled background refreshes (for notifications or widget content) must be efficient and respect OS constraints.
- **Platform-specific UX**: Document and implement platform-specific behavior for back navigation, system share sheet, and multi-window support where applicable.

Testable acceptance criteria:

- App links open app correctly on Android and iOS devices.
- Widget tap opens the app to the expected content.
- Native permission denied scenarios are handled gracefully.
