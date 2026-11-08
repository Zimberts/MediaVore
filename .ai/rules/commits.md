---
description: "Use when committing, naming a branch, or opening/renaming a pull request — Conventional Commits for commit messages AND PR titles, allowed types, free scope, readable branch names."
---

# Commits, PR titles and branches

Every commit message **and** every PR title follows
[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```text
<type>(<scope>)!: <description>
```

- **Types** (closed list): `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
  `build`, `ci`, `chore`, `revert`, `bump` (`bump` = version bump).
- **Scope** is optional and free: the feature or area touched, e.g. `export`,
  `media_details`, `stats`, `back`, `front`.
- `!` before `:` marks a breaking change. Description: imperative, lowercase start, no
  trailing period.
- Reverts: write `revert: <original subject>` — git's default `Revert "..."` is rejected.
- `Merge ...` commits pass. `fixup!`/`squash!` pass locally but fail CI: autosquash them
  (`git rebase -i --autosquash`) before the PR is merged.

Examples: `feat(stats): add yearly watch time`, `fix(export): readable filename`,
`ci: enforce Conventional Commits`, `bump: 1.4.0`.

## Branches

Branch names are readable and reference the issue: `<type>/<issue>-<short-slug>`, e.g.
`feat/233-readable-export-filename`, `ci/243-conventional-commits`. Never a generated
name such as `claude/project-thread-xxxx`.

## Enforcement

- Local: `.pre-commit-config.yaml` runs `conventional-pre-commit` at the `commit-msg`
  stage (`pip install pre-commit && pre-commit install --hook-type commit-msg`).
- CI: `.github/workflows/pr-title.yml` checks the PR title (re-runs on title edit) and
  every commit subject of the PR. With squash-merge the PR title becomes the commit on
  `main`.
- The type list lives in three places — keep `.pre-commit-config.yaml`,
  `.github/workflows/pr-title.yml` and `AGENTS.md` in sync.
