import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  createFallbackReleaseInfo,
  extractSha256FromText,
  formatFileSize,
  formatReleaseDate,
  parseReleasePayload,
  STABLE_APK_URL,
} from '../src/lib/release.ts';

describe('release metadata helpers', () => {
  it('should extract a 64-char hex digest from a sha256sum file', () => {
    const sample =
      'A3F1B2C3D4E5F60718293A4B5C6D7E8F90123456789ABCDEF0123456789ABCDE  mediavore-v1.4.4.apk\n';
    assert.equal(
      extractSha256FromText(sample),
      'a3f1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcde',
    );
  });

  it('should return null when no valid digest is present', () => {
    assert.equal(extractSha256FromText('no hash here'), null);
    assert.equal(extractSha256FromText(null), null);
  });

  it('should prefer stable mediavore.apk asset and parse sha256 asset', () => {
    const digest = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    const info = parseReleasePayload(
      {
        tag_name: 'v1.4.4',
        published_at: '2026-11-20T12:00:00Z',
        assets: [
          {
            name: 'mediavore-v1.4.4.apk',
            size: 25 * 1024 * 1024,
            browser_download_url: 'https://example.com/mediavore-v1.4.4.apk',
          },
          {
            name: 'mediavore.apk',
            size: 25 * 1024 * 1024,
            browser_download_url: 'https://example.com/mediavore.apk',
          },
        ],
      },
      `${digest}  mediavore.apk`,
    );

    assert.equal(info.version, 'v1.4.4');
    assert.equal(info.apkUrl, 'https://example.com/mediavore.apk');
    assert.equal(info.sizeBytes, 25 * 1024 * 1024);
    assert.equal(info.sha256, digest);
    assert.equal(info.isFallback, false);
  });

  it('should fall back to versioned apk and release body sha256 when stable asset is absent', () => {
    const digest = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
    const info = parseReleasePayload({
      tag_name: 'v1.4.3',
      published_at: '2026-11-10T10:00:00Z',
      body: `### Android APK\n\`\`\`\n${digest}  mediavore-v1.4.3.apk\n\`\`\``,
      assets: [
        {
          name: 'mediavore-v1.4.3.apk',
          size: 24 * 1024 * 1024,
          browser_download_url: 'https://example.com/mediavore-v1.4.3.apk',
        },
      ],
    });

    assert.equal(info.apkUrl, 'https://example.com/mediavore-v1.4.3.apk');
    assert.equal(info.sha256, digest);
  });

  it('should provide a working fallback release object', () => {
    const fallback = createFallbackReleaseInfo();
    assert.equal(fallback.apkUrl, STABLE_APK_URL);
    assert.equal(fallback.isFallback, true);
    assert.equal(fallback.version, null);
  });

  it('should format file sizes and dates cleanly', () => {
    assert.equal(formatFileSize(26214400, 'en'), '25.0 MB');
    assert.equal(formatFileSize(null, 'en'), null);
    assert.ok(formatReleaseDate('2026-11-20T12:00:00Z', 'en'));
    assert.equal(formatReleaseDate('not-a-date', 'en'), null);
  });
});
