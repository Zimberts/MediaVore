# AI-Ready Guidelines

This document explains how to make **any repository** easy for AI coding agents to
work with — GitHub Copilot (VS Code), OpenAI Codex, Cursor, Claude Code, Gemini CLI,
and others.

It is a **blueprint**, not a piece of configuration itself. Hand it to another agent
(or a human contributor) and ask them to _"set up the AI-enablement files described
in this document."_ The agent creates the files in
[§2 Directory layout](#2-directory-layout), fills them following
[§5 What to write](#5-what-to-write), and changes nothing else.

---

## 1. Core principle

AI agents work best with **discoverable, predictable context**. Put small,
well-named files in the places agents already look for them, rather than expecting
an agent to guess where your conventions live.

Two mechanisms work together:

1. **Global instructions** — a small, always-loaded file with project-wide defaults.
2. **Localized context** — files placed _near the code they describe_ (or scoped to
   matching file patterns), loaded only when relevant.

The most effective setup uses **both**: one lightweight global file plus targeted
local files, rather than one huge "kitchen sink" file.

---

## 2. Directory layout

The **global instruction file lives at the repository root** — `AGENTS.md` — because
that is the location Copilot (and other agents) auto-discover. The optional,
on-demand extras live under a **`.ai/`** folder, following the conventions
established by GitHub Copilot and OpenAI Codex (`rules`, `prompts`, `agents`,
`skills`, `hooks`, `commands`).

```
AGENTS.md               # Global, always-loaded instructions — at the ROOT (see §3)
.ai/
├── rules/               # Focused instruction files loaded on demand or by pattern
├── prompts/             # Reusable slash-command task templates
├── agents/              # Custom agent personas (optional)
├── skills/              # On-demand multi-step workflows (optional)
├── hooks/               # Deterministic lifecycle automation (optional)
└── commands/            # Simple CLI-style commands (optional, Codex-style)
```

> **Why the root?** `AGENTS.md` is the single most portable instruction file, and
> Copilot/Codex/Cursor/Gemini CLI look for it at the repository root (or in nested
> folders for monorepos). It must **not** be tucked under `.ai/`, where it won't be
> auto-loaded. `.ai/` holds only the optional, tool-specific extras.

### What each file/folder is for

| Path                         | Purpose                                          | Create when                                  |
| ---------------------------- | ------------------------------------------------ | -------------------------------------------- |
| `AGENTS.md` (root)           | Project-wide, always-on guidance                 | Always — start here                          |
| `.ai/rules/*.md`             | Narrow instructions for a task area or file type | A concern only matters for some files        |
| `.ai/prompts/*.prompt.md`    | Reusable single-task templates (slash commands)  | A repeated, well-defined generation task     |
| `.ai/agents/*.agent.md`      | Focused personas with restricted tools           | A repeated, well-bounded role                |
| `.ai/skills/<name>/SKILL.md` | Multi-step workflow with bundled assets          | A repeatable multi-step procedure            |
| `.ai/hooks/*.json`           | Hard enforcement (block commands, auto-format)   | Behavior must be _guaranteed_, not suggested |
| `.ai/commands/*.md`          | Simple one-shot commands                         | Quick, frequent actions                      |

---

## 3. The global instruction file (`AGENTS.md`)

`AGENTS.md` is the "README for agents": a dedicated, predictable place for the
context and instructions a coding agent needs — build steps, test commands, and
conventions that would clutter a human-facing `README.md`.

### Placement

- **Repository root** — the standard, auto-discovered location. Copilot, Codex,
  Cursor, Gemini CLI, Aider, goose, and others all look for `AGENTS.md` at the root.
  Do **not** place it under `.ai/` or another subfolder, or it won't be auto-loaded.
- **Nested** — you may place additional `AGENTS.md` files in subfolders/packages.
  Agents read the _closest_ one to the file being edited, so each subproject can ship
  tailored instructions. (This is the modern answer to "put instruction files in the
  sources" — still valid, see §7.)

### Content skeleton

Keep it concise — only what applies to _every_ task:

```markdown
# Project Guidelines

## Code Style

{Language/formatting preferences; reference files that exemplify patterns}

## Architecture

{Major components, boundaries, the "why" behind structure}

## Build and Test

{Exact commands to install, build, test, lint — agents will run these}

## Conventions

{Patterns that differ from common practice, with concrete examples}
```

### Rules of thumb

- **Minimal by default.** Only guidance relevant to every task.
- **Link, don't embed.** Point to existing docs instead of copying them.
- **Keep current.** Update as practices change.
- **Don't duplicate** what a linter/formatter already enforces.

---

## 4. Scoped instruction files (`rules/`)

Use these when a rule matters only for _some_ files or tasks. Two discovery modes:

- **On-demand** — a keyword-rich `description` lets the agent decide it's relevant.
- **Explicit** — an `applyTo` glob loads the file when matching files are touched.

Example (`.ai/rules/testing.md`):

```markdown
---
description: "Use when writing or editing tests. Covers mocking, fixtures, and naming conventions."
applyTo: "test/**"
---

# Testing guidelines

- Mock with the project's standard mocking library.
- Mirror source paths in the test tree.
- Name tests `test('should … when …')`.
```

Rules:

- One concern per file (testing, styling, migrations, API design…).
- Keyword-rich `description` (use the `"Use when…"` pattern).
- Keep `applyTo` narrow — avoid `"**"` unless truly global.

---

## 5. What to write (the categories)

Regardless of which file holds them, an agent needs the following kinds of
information. This is a **generic checklist** — fill in your project's specifics.

1. **Build & test commands** — the exact commands an agent should run to verify its
   work (install, build, test, lint). Agents will attempt to run these.
2. **Code style** — naming, file layout, formatting; prefer referencing the config
   files that already enforce these (`analysis_options.yaml`, `tsconfig.json`,
   `pyproject.toml`, `.eslintrc`, …).
3. **Architecture** — layer boundaries, where things go, and _why_.
4. **Conventions** — anything non-obvious or different from common practice.
5. **Gotchas** — traps an agent is likely to hit: generated files that must be
   regenerated, files not to commit, config that isn't read at runtime, etc.
6. **Workflow** — commit message format, PR process, CI.

---

## 6. Keeping it effective

- **Prefer guidance over enforcement.** Use plain instructions to _guide_ behavior;
  reserve `.ai/hooks/` for things that must be _guaranteed_ (blocking dangerous
  commands, deterministic formatting, injecting context).
- **Beware context bloat.** Every always-loaded file consumes context on every
  interaction. Keep global files small; push detail into scoped or on-demand files.
- **Avoid duplication.** Link to canonical docs rather than re-stating them. If two
  files say the same thing, one will drift out of date.
- **Start minimal, grow deliberately.** Begin with `AGENTS.md`; add `rules/`,
  `prompts/`, `agents/`, and `skills/` only as concrete needs emerge.

---

## 7. Localized files in the source tree

An older (and still-valid) practice is to place instruction files directly inside
the source tree, near the code they describe. This is **not obsolete** — it is
complementary to a single global file:

- **Nested `AGENTS.md`** — closest file wins; ideal for monorepos/packages.
- **`applyTo`-scoped rules** — instructions load only when matching files are edited.
- **Per-directory rules** — some tools (e.g. Cursor) support rules in subfolders.

Use localized files when a piece of context is only relevant to a specific area.
The trade-offs are **duplication/drift** (the same rule stated in multiple places)
and **discoverability** (agents must actually look there). Keep localized context
narrow and link back to the canonical global file.

---

## 8. Verification checklist

After scaffolding the AI-enablement files, confirm:

- [ ] A single global instruction file exists at the repository root (`AGENTS.md`).
- [ ] The global file is concise; it links to docs rather than copying them.
- [ ] Scoped `rules/` files use narrow `applyTo` globs and keyword-rich descriptions.
- [ ] No generated/runtime artifacts are accidentally committed.
- [ ] The project still builds and tests pass.
- [ ] No unrelated files were modified.
