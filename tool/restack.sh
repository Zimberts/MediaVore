#!/usr/bin/env bash
set -euo pipefail

# tool/restack.sh <old-parent-ref-or-sha> [target-branch-or-stack-top]
#
# Restacks a child branch (or multi-level stack) onto origin/main after the parent
# was squash-merged into main.
#
# Examples:
#   tool/restack.sh feat/301-theme-tokens feat/302-shared-components
#   tool/restack.sh 2a61306 feat/303-five-tab-shell

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <old-parent-ref-or-sha> [target-branch-or-stack-top]" >&2
  exit 1
fi

OLD_PARENT="$1"
TARGET_BRANCH="${2:-$(git rev-parse --abbrev-ref HEAD)}"

echo "==> Fetching origin..."
git fetch origin

# Enable updateRefs to automatically move intermediate stack branches
git config rebase.updateRefs true

echo "==> Switching to $TARGET_BRANCH..."
git checkout "$TARGET_BRANCH"

echo "==> Rebasing onto origin/main from $OLD_PARENT..."
git rebase --onto origin/main "$OLD_PARENT" "$TARGET_BRANCH"

echo "==> Rebase completed cleanly."
echo "==> Commits now on $TARGET_BRANCH (origin/main..$TARGET_BRANCH):"
git log --oneline --graph "origin/main..$TARGET_BRANCH"
echo ""
echo "To push:"
echo "  git push --force-with-lease origin $TARGET_BRANCH"
