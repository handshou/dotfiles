#!/bin/sh
# PreToolUse(Bash) gate: require a recent Plannotator run before `git commit`.
#
# Behaviour:
#   - Non-commit commands: stay out of the way (exit 0, no output -> normal flow).
#   - `git commit` with a fresh Plannotator marker (run within $WINDOW seconds): allow.
#   - `git commit` with an explicit bypass token in the command: allow.
#   - `git commit` otherwise: DENY, with instructions to run Plannotator first.
#
# Explicit bypass: prefix the command with  PLANNOTATOR_BYPASS=1
#   e.g.  PLANNOTATOR_BYPASS=1 git commit -m "..."
# The bypass must be stated explicitly per-commit; it is never implied.

WINDOW=1800   # 30 minutes
MARKER="$HOME/.claude/cache/plannotator-last-run"

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only gate actual git commits (matches `git ... commit`, incl. `git -C dir commit`,
# `git --git-dir=... commit`, `git commit --amend`). Word-boundaries avoid "committee".
if ! printf '%s' "$cmd" | grep -Eq 'git\b.*\bcommit\b'; then
  exit 0
fi

# Explicit, per-commit bypass.
case "$cmd" in
  *PLANNOTATOR_BYPASS=1*) exit 0 ;;
esac

# Fresh Plannotator marker?
if [ -f "$MARKER" ]; then
  last=$(cat "$MARKER" 2>/dev/null || echo 0)
  case "$last" in (*[!0-9]*|"") last=0 ;; esac
  now=$(date +%s)
  age=$((now - last))
  if [ "$age" -ge 0 ] && [ "$age" -le "$WINDOW" ]; then
    exit 0
  fi
fi

reason="Plannotator has not been run for this change (no run in the last $((WINDOW/60)) min). Before committing: run /plannotator-review for code or /plannotator-annotate for docs/plans, address the annotations that come back, then commit again. To skip ONLY when the user has explicitly authorized a bypass, re-issue the command prefixed with PLANNOTATOR_BYPASS=1 (e.g. PLANNOTATOR_BYPASS=1 git commit -m \"...\"). Never add the bypass on your own initiative."

jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
