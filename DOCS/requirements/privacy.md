# Privacy & Data Management Requirements

Purpose: specify minimal privacy guarantees and data controls for users.

- **Telemetry**: Telemetry/analytics must be opt‑in. Provide a clear explanation in settings and the first-run flow.
- **Data export**: Allow users to export saved lists and seen history as JSON with version metadata.
- **Data deletion**: Provide an in-app action to delete local data (lists, seen history, cache) and clear exports where applicable.
- **Minimal PII**: Avoid collecting personally identifying information. If any is stored, require explicit consent and document storage location.
- **Retention**: Default retention settings for seen history should be reasonable (configurable), and clearly documented.
- **Third-party services**: Document any third-party endpoints and the data sent to them.

Testable acceptance criteria:

- Telemetry is disabled until user opts in and toggling the opt‑in updates behavior immediately.
- Exported JSON contains only the agreed fields and version metadata.
