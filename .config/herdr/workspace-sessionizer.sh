#!/usr/bin/env bash
set -euo pipefail

select_workspace_directory() {
  find "$HOME/g" "$HOME/.config" "$HOME/Developer" "$HOME/Code/work" "$HOME/Code/personal" \
    -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | sort -u \
    | fzf --prompt='Herdr workspace> '
}

find_workspace_for_directory() {
  local selected_directory=$1

  herdr pane list | jq -r --arg selected_directory "$selected_directory" '
    first(
      .result.panes[]
      | select(
          .cwd == $selected_directory
          or .foreground_cwd == $selected_directory
        )
    ).workspace_id // empty
  '
}

hydrate_main_tab() {
  local workspace_id=$1
  local selected_directory=$2
  local main_directory="$selected_directory/main"

  if [[ ! -d "$main_directory" ]]; then
    return
  fi

  local tab_response root_pane_id
  tab_response=$(herdr tab create \
    --workspace "$workspace_id" \
    --cwd "$main_directory" \
    --label main \
    --focus)
  root_pane_id=$(jq -r '.result.root_pane.pane_id' <<<"$tab_response")
  herdr pane run "$root_pane_id" 'nvim .' >/dev/null
}

open_or_create_herdr_workspace() {
  local selected_directory=${1:-}

  if [[ -z "$selected_directory" ]]; then
    selected_directory=$(select_workspace_directory)
  fi
  if [[ -z "$selected_directory" ]]; then
    return
  fi
  if [[ ! -d "$selected_directory" ]]; then
    printf 'Herdr workspace sessionizer: directory does not exist: %s\n' "$selected_directory" >&2
    return 1
  fi

  selected_directory=$(cd "$selected_directory" && pwd -P)

  local workspace_id
  workspace_id=$(find_workspace_for_directory "$selected_directory")
  if [[ -n "$workspace_id" ]]; then
    herdr workspace focus "$workspace_id" >/dev/null
    return
  fi

  local workspace_label workspace_response
  workspace_label=$(basename "$selected_directory" | tr . _)
  workspace_response=$(herdr workspace create \
    --cwd "$selected_directory" \
    --label "$workspace_label" \
    --focus)
  workspace_id=$(jq -r '.result.workspace.workspace_id' <<<"$workspace_response")
  hydrate_main_tab "$workspace_id" "$selected_directory"
}

open_or_create_herdr_workspace "${1:-}"
