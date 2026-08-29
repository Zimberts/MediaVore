---
description: "Generate subfoldered AGENTS.md files throughout lib/ and test/ using a swarm of subagents. Use when adding localized guidance near the code (one AGENTS.md per feature and per core subfolder)."
argument-hint: "Folders: lib,test (or a specific subtree)"
---

Generate localized, subfoldered `AGENTS.md` files throughout this repository's
source tree, following the blueprint's §7 "localized files near the code" pattern.

## Goal

Place a concise `AGENTS.md` in each meaningful source subfolder so that agents
editing code there get area-specific context without loading the whole repo.

## Target folders

Dispatch a read-only subagent per folder to summarize it, then write one
`AGENTS.md` per folder. Cover:

- `lib/features/<feature>/` — one per feature (`achievements`, `discovery`,
  `media_details`, `search`, `settings`). Also create a nested one inside a
  feature's sub-layers **only** when that layer is large enough to need it
  (e.g. `lib/features/media_details/data/models/`, which holds the Isar
  collections).
- `lib/core/<sub>/` — one per shared subfolder (`cache`, `database`, `di`,
  `domain/entities`, `error`, `services`, `theme`, `utils`).
- `test/features/<feature>/` — one per tested feature, mirroring `lib/features/`.
- `test/core/<sub>/` and `test/helpers/` — as needed.

**Do NOT** create AGENTS.md in: generated/scratch dirs (`test/tmp*`), leaf folders
with a single trivial file, or anywhere that would duplicate the parent.

## Content rules (per file)

Each subfolder `AGENTS.md` must be short (≤ 30 lines) and contain only:

1. **One-line responsibility** — what this folder owns.
2. **Key files** — the 2–5 canonical files, with full relative paths.
3. **Area conventions / gotchas** — anything non-obvious specific to this folder
   (e.g. Isar `@collection` models + generated `.g.dart`; DI bindings; datasource
   patterns).
4. **A link up** — to the nearest parent `AGENTS.md` (and root `AGENTS.md`) rather
   than re-stating project-wide rules.

Link, don't embed: reference the root `AGENTS.md`, `.ai/rules/*.md`, and sibling
docs instead of copying their content. Never invent conventions — verify each
claim against the actual files.

## Swarm procedure

1. Enumerate the folders to document (as above).
2. Spawn one read-only subagent per folder to map its contents (files, layers,
   patterns, generated-file gotchas).
3. Write one `AGENTS.md` per folder from each subagent's summary.
4. Verify: every file links to its parent; no project-wide rule is duplicated;
   no file landed in a scratch/generated dir; no Dart source was modified.

## Constraints

- Do NOT modify any Dart source, `pubspec.yaml`, or `analysis_options.yaml`.
- Do NOT overwrite the existing top-level `lib/AGENTS.md`, `test/AGENTS.md`, or
  `DOCS/AGENTS.md` — the swarm only adds subfolder files below them.
- Do NOT create `AGENTS.md` in `test/tmp*`, `build/`, `.dart_tool/`, or `.ai/`.
