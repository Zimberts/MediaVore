---
description: "Run the ai-enablement swarm to generate this repo's AI guidance (root AGENTS.md, .ai rules/prompts/skills/hooks, nested AGENTS.md). Delegates to the ai-enablement-generation skill."
argument-hint: "Scope: full or minimal"
---
Follow the `ai-enablement-generation` skill to AI-enable this repository.

Required inputs:
- **scope**: `full` (root `AGENTS.md` + `.ai/rules` + `.ai/prompts` + `.ai/skills` + `.ai/hooks` + `.ai/commands` + nested `AGENTS.md` near code) or `minimal` (root `AGENTS.md` + core rules only). Default: `full`.
- **features**: which feature folders to document in nested guidance (default: `media_details` as the pilot, plus `lib/`, `test/`, `DOCS/`).

Constraints:
- Do not modify any Dart source, `pubspec.yaml`, or `analysis_options.yaml`.
- Do not uncomment `.github/workflows/android-build.yml`.
- End by running the verifier and reporting PASS/FAIL per the blueprint §8 checklist.
