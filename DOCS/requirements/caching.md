# Caching & Offline Requirements

Purpose: define cache behavior for API data and offline UX expectations.

- **Cache scopes**: Cache should cover discovery pages, recently seen, and thumbnails separately.
- **Manual controls**: Settings must expose `Get cache size`, `Clear cache (partial)`, and `Clear cache (complete)` actions.
- **Prefetching**: Allow manual or scheduled prefetch to fill common lists ("fill cache"). Prefetch runs respect network constraints (Wi‑Fi, battery saver).
- **Eviction policy**: Use LRU or time-based eviction; ensure thumbnails have separate size limits from metadata.
- **Offline behavior**: When offline, app uses cached discovery and details; show clear offline indicator and stale timestamps.
- **Progress indicators**: Long-running cache actions report progress and can be cancelled from UI.
- **Storage limits**: Enforce an overall cache size limit configurable in settings; warn users when near limit.
- **Data validity**: Cached metadata carries a TTL after which the UI should visibly mark it as potentially stale.

Testable acceptance criteria:

- Settings show accurate cache size and clearing updates size.
- Prefetch path (`fillCache`) runs and marks `_isCacheLoading` while running.
- Offline navigation to previously-viewed details works without network.
