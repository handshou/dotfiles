#!/usr/bin/env bash
# Window label for tmux. Display priority:
#   1. [PR#] when an open GitHub PR exists for the current branch
#   2. the branch name if it is a git repo with a branch
#   3. the folder basename as final fallback
# The gh lookup is cached and refreshed in the background so the status
# bar never blocks.

DIR="$1"
[[ -z "$DIR" ]] && exit 0

FOLDER=$(basename "$DIR")

cd "$DIR" 2>/dev/null || { echo "$FOLDER"; exit 0; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "$FOLDER"; exit 0; }

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ -z "$BRANCH" ]] && { echo "$FOLDER"; exit 0; }

HASH=$(echo "$DIR" | shasum 2>/dev/null | awk '{print $1}')
SAFE_BRANCH="${BRANCH//[^a-zA-Z0-9]/_}"
CACHE="/tmp/tmux-pr-${HASH}-${SAFE_BRANCH}"
TTL=60

NOW=$(date +%s)
MTIME=0
[[ -f "$CACHE" ]] && MTIME=$(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE" 2>/dev/null || echo 0)

PR=""
if [[ -f "$CACHE" ]] && (( NOW - MTIME < TTL )); then
  PR=$(cat "$CACHE")
else
  [[ -f "$CACHE" ]] && PR=$(cat "$CACHE")
  (
    if command -v gh &>/dev/null && cd "$DIR" 2>/dev/null; then
      NEW_PR=$(gh pr view "$BRANCH" --json number --jq '.number' 2>/dev/null || true)
      printf '%s' "$NEW_PR" > "$CACHE"
    fi
  ) >/dev/null 2>&1 &
fi

if [[ -n "$PR" ]]; then
  echo "[$PR]"
else
  echo "$BRANCH"
fi
