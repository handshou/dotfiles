#!/usr/bin/env bash
# Claude Code status line: model | dir | in: Xk  out: Xk
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "claude"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""' | xargs basename 2>/dev/null)

total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

fmt_k() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
  else
    printf "%d" "$n"
  fi
}

in_fmt=$(fmt_k "$total_in")
out_fmt=$(fmt_k "$total_out")

printf "%s  %s  in:%s out:%s" "$model" "$dir" "$in_fmt" "$out_fmt"
