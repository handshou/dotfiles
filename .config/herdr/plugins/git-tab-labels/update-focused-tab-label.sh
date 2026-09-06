#!/usr/bin/env bash
set -euo pipefail

readonly MAX_BRANCH_LABEL_LENGTH=24

get_event_pane() {
  local event_json=$1
  local pane_json pane_id

  pane_json=$(jq -c '.pane // empty' <<<"$event_json")
  if [[ -n "$pane_json" ]]; then
    printf '%s\n' "$pane_json"
    return
  fi

  pane_id=$(jq -r '.pane_id // empty' <<<"$event_json")
  if [[ -n "$pane_id" ]]; then
    "$HERDR_BIN_PATH" pane get "$pane_id" | jq -c '.result.pane'
    return
  fi

  local tab_id workspace_id
  tab_id=$(jq -r '.tab_id // .tab.tab_id // empty' <<<"$event_json")
  workspace_id=$(jq -r '.workspace_id // .tab.workspace_id // empty' <<<"$event_json")
  if [[ -z "$tab_id" || -z "$workspace_id" ]]; then
    return
  fi

  "$HERDR_BIN_PATH" pane list --workspace "$workspace_id" | jq -c --arg tab_id "$tab_id" '
    first(.result.panes[] | select(.tab_id == $tab_id and .focused))
    // first(.result.panes[] | select(.tab_id == $tab_id))
    // empty
  '
}

get_open_github_pr_number() {
  local repository_directory=$1
  local branch=$2
  local directory_hash safe_branch cache_path now modified_at

  directory_hash=$(printf '%s' "$repository_directory" | shasum | awk '{print $1}')
  safe_branch=${branch//[^a-zA-Z0-9]/_}
  cache_path="${TMPDIR:-/tmp}/herdr-tab-pr-${directory_hash}-${safe_branch}"
  now=$(date +%s)
  modified_at=0
  if [[ -f "$cache_path" ]]; then
    modified_at=$(stat -f %m "$cache_path" 2>/dev/null || stat -c %Y "$cache_path" 2>/dev/null || printf '0')
  fi

  if [[ -f "$cache_path" && $((now - modified_at)) -lt 60 ]]; then
    cat "$cache_path"
    return
  fi

  local pr_number=""
  if command -v gh >/dev/null 2>&1; then
    if command -v direnv >/dev/null 2>&1; then
      pr_number=$(direnv exec "$repository_directory" gh pr list --head "$branch" --state open --json number --jq '.[0].number // empty' 2>/dev/null || true)
    else
      pr_number=$(cd "$repository_directory" && gh pr list --head "$branch" --state open --json number --jq '.[0].number // empty' 2>/dev/null || true)
    fi
  fi
  printf '%s' "$pr_number" >"$cache_path"
  printf '%s' "$pr_number"
}

shorten_branch_label() {
  local branch=$1
  if ((${#branch} <= MAX_BRANCH_LABEL_LENGTH)); then
    printf '%s' "$branch"
    return
  fi
  printf '%s…' "${branch:0:MAX_BRANCH_LABEL_LENGTH-1}"
}

update_focused_tab_label() {
  local event_json=${HERDR_PLUGIN_EVENT_JSON:-}
  if [[ -z "$event_json" ]]; then
    printf 'Git tab labels: HERDR_PLUGIN_EVENT_JSON is missing\n' >&2
    return 1
  fi

  local event_data pane_json focused tab_id pane_directory repository_directory branch pr_number label current_label
  event_data=$(jq -c '.data // .' <<<"$event_json")
  pane_json=$(get_event_pane "$event_data")
  if [[ -z "$pane_json" ]]; then
    return
  fi

  focused=$(jq -r '.focused // false' <<<"$pane_json")
  if [[ "$focused" != "true" ]]; then
    return
  fi

  tab_id=$(jq -r '.tab_id' <<<"$pane_json")
  pane_directory=$(jq -r '.foreground_cwd // .cwd // empty' <<<"$pane_json")
  if [[ -z "$tab_id" || -z "$pane_directory" ]]; then
    return
  fi

  repository_directory=$(git -C "$pane_directory" rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -z "$repository_directory" ]]; then
    label=$(basename "$pane_directory")
  else
    branch=$(git -C "$repository_directory" branch --show-current 2>/dev/null || true)
    if [[ -z "$branch" ]]; then
      label=$(basename "$repository_directory")
    else
      pr_number=$(get_open_github_pr_number "$repository_directory" "$branch")
      if [[ -n "$pr_number" ]]; then
        label="PR#$pr_number"
      else
        label=$(shorten_branch_label "$branch")
      fi
    fi
  fi

  current_label=$("$HERDR_BIN_PATH" tab get "$tab_id" | jq -r '.result.tab.label // empty')
  if [[ -n "$label" && "$label" != "$current_label" ]]; then
    "$HERDR_BIN_PATH" tab rename "$tab_id" "$label" >/dev/null
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  update_focused_tab_label
fi
