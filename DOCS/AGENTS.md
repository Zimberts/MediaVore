# DOCS/ — conventions

For project-wide rules, see the root [`AGENTS.md`](../AGENTS.md).

## Authoritative docs

- `DOCS/export-format.md` is the **authoritative spec** for the ZIP-of-CSV export/import
  format. It must stay in sync with `lib/core/utils/export_import_serializer.dart` — see
  `.ai/rules/export-format.md` for the full schema and `ImportMode` semantics.
- `DOCS/ai-guidelines.md` is the blueprint for this repo's AI-enablement files (root
  `AGENTS.md`, `.ai/rules/`, `.ai/agents/`, etc.).

## Keep-in-sync rule

When a change alters the export schema or import behavior, update `export-format.md` in
the same change and bump `meta.csv` `version` if the change is breaking.
