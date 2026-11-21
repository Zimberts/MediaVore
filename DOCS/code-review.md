# AI code review with Open Code Review

[Open Code Review](https://github.com/alibaba/open-code-review) (`ocr`,
Apache-2.0) structures an AI review of a Git diff: it selects the files to
review, groups them, and attaches review rules to each file. The project
rules live in [`.opencodereview/rule.json`](../.opencodereview/rule.json);
`ocr` loads them automatically.

The review is advisory and local: nothing runs in CI, so it costs no API
key. CI stays the gate (analyze, format, tests, coverage).

## Setup (once)

```sh
npm install -g @alibaba-group/open-code-review   # Git >= 2.41 required
```

Then, in Claude Code, install the plugin (it adds the slash commands below):

```text
/plugin marketplace add alibaba/open-code-review
/plugin install open-code-review@open-code-review
```

Other agents (Codex, Cursor…): `npx skills add alibaba/open-code-review` and
pick `open-code-review-delegate`.

## Review a branch before opening a PR

Delegation mode needs no OCR model provider: `ocr` picks the files and the
rules, and your coding agent (Claude Code, Codex, Cursor…) does the review
with its own model.

In Claude Code, from the repository root:

```text
/open-code-review:delegate-review --from main
```

With the skill instead of the plugin, ask: *"Review my branch against main
with the open-code-review-delegate skill."*

To see what would be reviewed, and with which rules, without an agent:

```sh
ocr delegate preview --from main
ocr delegate rule --from main lib/path/to/file.dart
```

Native mode (`ocr review --from main`) runs OCR's own agent and needs a
model provider (`ocr config provider`); it is optional.

## What the project rules add

The built-in rules have nothing specific to Dart. `rule.json`:

- reviews `lib/l10n/*.arb` (skipped by default) and skips generated code
  (`lib/l10n/generated/`, `*.g.dart`, `*.config.dart`);
- asks for the bugs the analyzer cannot see: fire-and-forget futures whose
  effects are read right after, optimistic updates that roll back too much,
  `context` used after `await` without `mounted`, failures not memoised in
  per-item loops;
- restates the project conventions from `CLAUDE.md` (layers, `debugPrint`,
  l10n, `isar_community`, generated files, tests).

Update `rule.json` when a review misses a class of bug the project cares
about, or keeps flagging something the project accepts.
