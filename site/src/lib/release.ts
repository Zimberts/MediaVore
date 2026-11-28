export interface GitHubAsset {
  name: string;
  size: number;
  browser_download_url: string;
}

export interface GitHubReleasePayload {
  tag_name?: string;
  published_at?: string;
  body?: string;
  assets?: GitHubAsset[];
}

export interface ReleaseInfo {
  version: string | null;
  publishedAt: string | null;
  apkUrl: string;
  releasesUrl: string;
  sizeBytes: number | null;
  sha256: string | null;
  isFallback: boolean;
}

export const REPO_SLUG = 'Zimberts/MediaVore';
export const STABLE_APK_URL = `https://github.com/${REPO_SLUG}/releases/latest/download/mediavore.apk`;
export const RELEASES_PAGE_URL = `https://github.com/${REPO_SLUG}/releases`;
export const REPO_URL = `https://github.com/${REPO_SLUG}`;

const SHA256_REGEX = /\b([a-fA-F0-9]{64})\b/;

export function extractSha256FromText(text: string | null | undefined): string | null {
  if (!text) return null;
  const match = SHA256_REGEX.exec(text);
  return match ? match[1].toLowerCase() : null;
}

export function formatFileSize(bytes: number | null, locale: string): string | null {
  if (bytes === null || !Number.isFinite(bytes) || bytes <= 0) return null;
  const megabytes = bytes / (1024 * 1024);
  return `${new Intl.NumberFormat(locale, {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  }).format(megabytes)} MB`;
}

export function formatReleaseDate(isoDate: string | null, locale: string): string | null {
  if (!isoDate) return null;
  const date = new Date(isoDate);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
}

export function parseReleasePayload(
  payload: GitHubReleasePayload,
  sha256AssetText: string | null = null,
): ReleaseInfo {
  const assets = Array.isArray(payload.assets) ? payload.assets : [];

  const stableApk = assets.find((asset) => asset.name === 'mediavore.apk');
  const versionedApk = assets.find(
    (asset) => asset.name.endsWith('.apk') && !asset.name.endsWith('.sha256'),
  );
  const apkAsset = stableApk ?? versionedApk ?? null;

  const sha256 =
    extractSha256FromText(sha256AssetText) ??
    extractSha256FromText(payload.body);

  return {
    version: payload.tag_name ?? null,
    publishedAt: payload.published_at ?? null,
    apkUrl: stableApk?.browser_download_url ?? apkAsset?.browser_download_url ?? STABLE_APK_URL,
    releasesUrl: RELEASES_PAGE_URL,
    sizeBytes: apkAsset?.size ?? null,
    sha256,
    isFallback: false,
  };
}

export function createFallbackReleaseInfo(): ReleaseInfo {
  return {
    version: null,
    publishedAt: null,
    apkUrl: STABLE_APK_URL,
    releasesUrl: RELEASES_PAGE_URL,
    sizeBytes: null,
    sha256: null,
    isFallback: true,
  };
}

function readEnvVar(name: string): string | undefined {
  const proc = (
    globalThis as { process?: { env?: Record<string, string | undefined> } }
  ).process;
  return proc?.env?.[name];
}

function buildAuthHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: 'application/vnd.github+json',
    'User-Agent': 'mediavore-site-build',
  };
  const token = readEnvVar('GITHUB_TOKEN') ?? readEnvVar('GH_TOKEN');
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

export async function fetchLatestRelease(): Promise<ReleaseInfo> {
  const headers = buildAuthHeaders();
  try {
    const response = await fetch(
      `https://api.github.com/repos/${REPO_SLUG}/releases/latest`,
      { headers, signal: AbortSignal.timeout(8000) },
    );
    if (!response.ok) {
      return createFallbackReleaseInfo();
    }

    const payload = (await response.json()) as GitHubReleasePayload;
    const assets = Array.isArray(payload.assets) ? payload.assets : [];
    const shaAsset =
      assets.find((asset) => asset.name === 'mediavore.apk.sha256') ??
      assets.find((asset) => asset.name.endsWith('.apk.sha256'));

    let shaText: string | null = null;
    if (shaAsset) {
      try {
        const shaResponse = await fetch(shaAsset.browser_download_url, {
          headers: { 'User-Agent': 'mediavore-site-build' },
          signal: AbortSignal.timeout(6000),
        });
        if (shaResponse.ok) {
          shaText = await shaResponse.text();
        }
      } catch {
        shaText = null;
      }
    }

    return parseReleasePayload(payload, shaText);
  } catch {
    return createFallbackReleaseInfo();
  }
}
