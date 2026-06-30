#!/usr/bin/env bash
# HEAL — Git sync helper.
# Run before any code change to ensure local + remote are in sync.
# Safe by default: refuses to overwrite uncommitted local changes.
#
# Usage:
#   ./scripts/git-sync.sh            # fetch + status check, no merge
#   ./scripts/git-sync.sh --pull     # fetch + fast-forward pull (default)
#   ./scripts/git-sync.sh --push     # commit + push (only what's safe)
#   ./scripts/git-sync.sh --auto     # pull, then attempt to push any local-only commits
#   ./scripts/git-sync.sh --help

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || { echo "❌ Not a git repo"; exit 1; })"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

action="status"
for arg in "$@"; do
  case "$arg" in
    --pull)  action="pull" ;;
    --push)  action="push" ;;
    --auto)  action="auto" ;;
    --help|-h)
      head -n 8 "$0" | tail -n 6
      exit 0
      ;;
    *) echo "Unknown arg: $arg"; exit 1 ;;
  esac
done

log() { echo -e "${BLUE}[sync]${NC} $*"; }
ok()  { echo -e "${GREEN}[ok]${NC} $*"; }
warn(){ echo -e "${YELLOW}[warn]${NC} $*"; }
err() { echo -e "${RED}[err]${NC} $*"; }

# ─── Step 1: refuse to run with dirty tree (unless --force) ────────
if [ -n "$(git status --porcelain)" ]; then
  err "Working tree has uncommitted changes."
  git status --short
  echo ""
  echo "Commit or stash first, then re-run. Refusing to sync to avoid losing work."
  exit 1
fi

# ─── Step 2: detect current branch ─────────────────────────────────
BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ]; then
  err "Detached HEAD. Re-checkout a branch first."
  exit 1
fi
log "Branch: $BRANCH"

# ─── Step 3: fetch remote ──────────────────────────────────────────
log "Fetching origin/$BRANCH ..."
git fetch origin "$BRANCH" --quiet 2>&1 || { err "Fetch failed"; exit 1; }

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")
BASE=$(git merge-base HEAD "origin/$BRANCH" 2>/dev/null || echo "0000000000000000000000000000000000000000")

# ─── Step 4: report state ──────────────────────────────────────────
AHEAD=$(git rev-list --count "origin/$BRANCH..HEAD")
BEHIND=$(git rev-list --count "HEAD..origin/$BRANCH")

echo ""
log "Status: $LOCAL | origin/$BRANCH: $REMOTE"
echo -e "  ${GREEN}AHEAD${NC} (local not pushed): $AHEAD"
echo -e "  ${YELLOW}BEHIND${NC} (remote not pulled): $BEHIND"
echo ""

if [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then
  err "Branches DIVERGED. Cannot fast-forward."
  echo "Resolve manually:"
  echo "  git pull --rebase origin $BRANCH"
  exit 1
fi

if [ "$LOCAL" = "$REMOTE" ]; then
  ok "Already in sync."
  exit 0
fi

# ─── Step 5: act based on mode ─────────────────────────────────────
case "$action" in
  status)
    if [ "$BEHIND" -gt 0 ]; then
      warn "Remote is ahead by $BEHIND commits. Run: $0 --pull"
    elif [ "$AHEAD" -gt 0 ]; then
      warn "Local is ahead by $AHEAD commits. Run: $0 --push"
    fi
    exit 0
    ;;

  pull)
    if [ "$BEHIND" -eq 0 ]; then
      ok "Nothing to pull."
      exit 0
    fi
    log "Fast-forward pulling $BEHIND commit(s) ..."
    git pull --ff-only origin "$BRANCH" 2>&1
    ok "Now at $(git rev-parse --short HEAD)"
    exit 0
    ;;

  push)
    if [ "$AHEAD" -eq 0 ]; then
      ok "Nothing to push."
      exit 0
    fi
    log "Pushing $AHEAD local commit(s) to origin/$BRANCH ..."
    git push origin "$BRANCH" 2>&1
    ok "Pushed."
    exit 0
    ;;

  auto)
    if [ "$BEHIND" -gt 0 ]; then
      log "Pulling first ..."
      git pull --ff-only origin "$BRANCH" 2>&1
    fi
    AHEAD=$(git rev-list --count "origin/$BRANCH..HEAD")
    if [ "$AHEAD" -gt 0 ]; then
      log "Pushing $AHEAD commit(s) ..."
      git push origin "$BRANCH" 2>&1
    fi
    ok "Auto-sync complete at $(git rev-parse --short HEAD)"
    exit 0
    ;;
esac