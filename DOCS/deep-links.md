# Deep Linking Configuration

To enable shared links (`https://mediavore.app/share`) to open MediaVore directly on Android without opening the browser first, host an Android App Links configuration file on your domain.

## Android App Links

Host a file at: `https://mediavore.app/.well-known/assetlinks.json`

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

Replace `YOUR_APP_SHA256_FINGERPRINT` with your actual release or debug certificate SHA-256 fingerprint.
