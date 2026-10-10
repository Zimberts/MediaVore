---
name: ai-enablement-generation
description: 'Orchestrate a swarm of subagents to AI-enable this repository: generate the root AGENTS.md, .ai rules, prompts, skills, hooks, commands, and nested AGENTS.md near the code, then verify. Use when implementing DOCS/ai-guidelines.md for this repo.'
argument-hint: 'Scope: full or minimal'
user-invocable: true
---
# AI-Enablement Generation

Generates the AI-guidance artifacts described in `DOCS/ai-guidelines.md` by coordinating a swarm of role agents. This skill is the conductor that runs the swarm; it does not write the artifacts itself.

## When to Use
- Implementing the blueprint for the first time (full scope).
- Regenerating or refreshing repo AI docs after major architecture changes.

## Prerequisites
- The role agents under `.ai/agents/` exist: `context-miner`, `agends-md-writer`, `rules-writer`, `prompts-writer`, `skills-writer`, `hooks-writer`, `verifier`.

## Procedure
1. **Mine context.** Invoke the `context-miner` agent to produce a Repo Context Brief. This is the single source of truth for all writers.
2. **Write in parallel.** Using the brief, invoke in any order (each reads the brief, not each other):
   - `agends-md-writer` → root `AGENTS.md`
   - `rules-writer` → `.ai/rules/*.md`, nested `AGENTS.md`, `.ai/commands/*.md`
   - `prompts-writer` → `.ai/prompts/*.prompt.md`
   - `skills-writer` → `.ai/skills/*/SKILL.md` (excluding this skill)
   - `hooks-writer` → `.ai/hooks/*.json` (or none)
3. **Verify.** Invoke the `verifier` agent. It checks the §8 checklist, frontmatter validity, applyTo globs, and runs `dart analyze` + `flutter test`.
4. **Iterate.** Feed verifier FAIL items back to the responsible writer agent; re-run verifier until clean (max 2 iterations, then report blockers).
5. **Report.** Summarize every created file and the verification result.

## Constraints
- Never modify Dart source code or `pubspec.yaml`.
- Never create a `hooks` file unless `hooks-writer` justifies it.
- Respect scope: `full` = blueprint §2-§8 + nested `AGENTS.md` near code; `minimal` = root `AGENTS.md` + core rules only.
