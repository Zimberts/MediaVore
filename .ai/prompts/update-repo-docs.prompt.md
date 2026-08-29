---
description: "Use when updating repo documentation — README.md, ACHIEVEMENTS.md, TODO.md, and DOCS/* — after a code change, following conventional commit scopes."
argument-hint: "Change type: feature | fix | chore | docs"
---

# Update Repo Docs

Update the repository's human- and agent-facing documentation to reflect a completed code change.

## Task

1. Determine which docs the change affects: `README.md`, `ACHIEVEMENTS.md`, `TODO.md`, `DOCS/export-format.md`, and/or `DOCS/ai-guidelines.md`.
2. Update only the docs that are actually impacted; do not rewrite unrelated sections.
3. Use conventional commit scopes when describing the change, and record completed work in `ACHIEVEMENTS.md` and `TODO.md` where appropriate.
4. If the change touches achievement definitions or export behavior, follow `.ai/rules/achievements.md` and `.ai/rules/export-format.md` respectively.

## Required inputs

- **change summary** — what was implemented or fixed, in conventional commit form (e.g. `feat(search): add …`).
- **affected docs** — the specific file(s) to update.
- **scope** — conventional commit scope (e.g. `search`, `media_details`, `core`).

## References

- Root `AGENTS.md` — project-wide documentation conventions.
- `.ai/rules/achievements.md` — `definitions.json` as single source of truth.
- `.ai/rules/export-format.md` — ZIP-of-CSV schema and `ImportMode` semantics.

## Constraints

- Do not modify Dart source or `pubspec.yaml` in this task.
- Do not change `DOCS/export-format.md` schema details without an accompanying code change.
