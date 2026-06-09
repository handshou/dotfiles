#!/usr/bin/env bash
# Wrapper around tokyo-night-tmux's battery widget.
# Suppresses output when on AC at 100%, so the widget hides in the common
# "plugged in, fully charged" state. Otherwise delegates to the plugin script.

BATTERY_NAME=$(tmux show-option -gv @tokyo-night-tmux_battery_name 2>/dev/null)
BATTERY_NAME="${BATTERY_NAME:-InternalBattery-0}"

PMSTAT=$(pmset -g batt 2>/dev/null | grep "$BATTERY_NAME")
if [[ -n "$PMSTAT" ]]; then
  STATUS=$(echo "$PMSTAT" | awk '{print $4}' | sed 's/[^a-zA-Z]*//g')
  PCT=$(echo "$PMSTAT" | awk '{print $3}' | sed 's/[^0-9]*//g')
  if [[ "$PCT" =~ ^[0-9]+$ && $PCT -ge 100 ]]; then
    case "$STATUS" in
    Charged | charged | Full | full | AC | Notcharging | Charging | charging)
      exit 0
      ;;
    esac
  fi
fi

exec "$HOME/.config/tmux/plugins/tokyo-night-tmux/src/battery-widget.sh"
