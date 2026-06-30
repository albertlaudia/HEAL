#!/usr/bin/env bash
# HEAL — Install git hooks to enforce sync-before-commit.
# Run once after cloning the repo.
#
# Usage: ./scripts/install-hooks.sh

set -e
HOOKS_DIR=".git/hooks"
PRE_COMMIT="$HOOKS_DIR/pre-commit"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "❌ .git/hooks/ not found. Are you at the repo root?"
  exit 1
fi

cp scripts/pre-commit-sync-check "$PRE_COMMIT"
chmod +x "$PRE_COMMIT"

echo "✓ Installed pre-commit hook at $PRE_COMMIT"
echo "  Bypass: GIT_HEAL_SKIP_SYNC=1 git commit ..."
echo "  Bulk mode: GIT_HEAL_QUIET=1 git commit ..."