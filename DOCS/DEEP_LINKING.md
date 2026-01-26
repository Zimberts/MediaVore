# Deep Linking Configuration

This document explains how to configure deep linking and app links for MediaVore.

## Android App Links

To enable shared links (for example `https://mediavore.app/share`) to open the app directly on Android instead of the browser, host a file on your domain.

Host a file at: `https://mediavore.app/.well-known/assetlinks.json`

Content:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.mediavore",
      "sha256_cert_fingerprints": ["YOUR_APP_SHA256_FINGERPRINT"]
    }
  }
]
```

Replace `YOUR_APP_SHA256_FINGERPRINT` with your actual release/debug certificate fingerprint.

## Notes

- Place platform-specific link configuration in this document so the `README.md` stays high-level and focused.
- If you would rather keep this information in the `README.md`, tell me and I will move it back.
