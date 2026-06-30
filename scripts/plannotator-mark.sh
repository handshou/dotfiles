#!/bin/sh
# PostToolUse(Skill) hook: record when a Plannotator skill is run.
# Writes a unix-timestamp marker that plannotator-gate.sh checks before allowing `git commit`.
input=$(cat)
name=$(printf '%s' "$input" | jq -r '.tool_input.skill // .tool_input.name // ""' 2>/dev/null)

case "$name" in
  *plannotator*)
    dir="$HOME/.claude/cache"
    mkdir -p "$dir"
    date +%s > "$dir/plannotator-last-run"
    ;;
esac
exit 0
