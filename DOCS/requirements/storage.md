# Storage & Data Requirements

Purpose: define expectations for local persistence, migrations, export/import, and retention.

- **Persistence engine**: Use Isar for local DB; data models must be normalized and versioned.
- **Schema versioning**: Every model change requires a migration plan and a versioned migration script.
- **Atomicity**: Writes that update related entities must be atomic from the app perspective.
- **Consistency**: Read-after-write consistency for recently changed items in the same session.
- **Export/Import**: Provide JSON export/import for saved lists and seen history; exports must include version metadata.
- **Backup & Restore**: Support manual restore from exported file; detect and report incompatible versions.
- **Retention & Purge**: Configurable retention for seen history; provide a UI control to purge history and a programmatic API.
- **Size reporting**: Expose approximate DB size to settings and to diagnostic screens.
- **Encryption & Privacy**: Sensitive user identifiers (if any) must not be included in telemetry exports by default.

Testable acceptance criteria:

- DB migrations run and pass on upgrade between two consecutive released versions.
- Exported JSON imports back to the same app and recreates lists and seen history.
- Purge operation removes records and updates DB size.
