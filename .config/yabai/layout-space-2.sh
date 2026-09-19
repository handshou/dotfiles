#!/bin/sh

# Restore the Space 2 BSP layout after its windows exist and the space is visible.
set -eu

TARGET_SPACE_INDEX=2
CHATGPT_HEIGHT_RATIO=0.43
LAYOUT_LOCK_DIRECTORY="${TMPDIR:-/tmp}/yabai-space-2-layout-$(id -u).lock"

# Window resizing is unreliable on an inactive macOS Space. The space_changed
# signal invokes this script again as soon as Space 2 becomes visible.
SPACE_IS_VISIBLE=$(yabai -m query --spaces --space "$TARGET_SPACE_INDEX" | jq -r '."is-visible"')
[ "$SPACE_IS_VISIBLE" = "true" ] || exit 0

# Coalesce window-created and title-changed signals that arrive together.
mkdir "$LAYOUT_LOCK_DIRECTORY" 2>/dev/null || exit 0
trap 'rmdir "$LAYOUT_LOCK_DIRECTORY"' EXIT INT TERM
sleep 0.5

WINDOWS=$(yabai -m query --windows)
PERSONAL_GHOSTTY_WINDOW_ID=$(printf '%s' "$WINDOWS" | jq -r --argjson space "$TARGET_SPACE_INDEX" '
  [.[] | select(
    .space == $space and
    .app == "Ghostty" and
    (.title | test("^PERSONAL( ·|$)"))
  )][0].id // empty
')
CHATGPT_WINDOW_ID=$(printf '%s' "$WINDOWS" | jq -r --argjson space "$TARGET_SPACE_INDEX" '
  [.[] | select(
    .space == $space and
    (.app == "ChatGPT" or .app == "OpenAI")
  )][0].id // empty
')
OBSIDIAN_WINDOW_ID=$(printf '%s' "$WINDOWS" | jq -r --argjson space "$TARGET_SPACE_INDEX" '
  [.[] | select(.space == $space and .app == "Obsidian")][0].id // empty
')

# Wait for a later signal if any member of the three-window layout is absent.
[ -n "$PERSONAL_GHOSTTY_WINDOW_ID" ] || exit 0
[ -n "$CHATGPT_WINDOW_ID" ] || exit 0
[ -n "$OBSIDIAN_WINDOW_ID" ] || exit 0

# Avoid visibly rebuilding an already-correct tree whenever Space 2 is focused.
LAYOUT_IS_ALREADY_NESTED=$(printf '%s' "$WINDOWS" | jq -r \
  --argjson ghostty "$PERSONAL_GHOSTTY_WINDOW_ID" \
  --argjson chatgpt "$CHATGPT_WINDOW_ID" \
  --argjson obsidian "$OBSIDIAN_WINDOW_ID" '
  ([.[] | select(.id == $ghostty)][0]) as $ghostty_window |
  ([.[] | select(.id == $chatgpt)][0]) as $chatgpt_window |
  ([.[] | select(.id == $obsidian)][0]) as $obsidian_window |
  $ghostty_window["split-type"] == "vertical" and
  $ghostty_window["split-child"] == "first_child" and
  $chatgpt_window["split-type"] == "horizontal" and
  $chatgpt_window["split-child"] == "first_child" and
  $obsidian_window["split-type"] == "horizontal" and
  $obsidian_window["split-child"] == "second_child"
')

# Ghostty occupies the full-height left column. ChatGPT and Obsidian share the
# right column, with Obsidian receiving the larger lower pane.
if [ "$LAYOUT_IS_ALREADY_NESTED" != "true" ]; then
  yabai -m window "$PERSONAL_GHOSTTY_WINDOW_ID" --insert east
  yabai -m window "$CHATGPT_WINDOW_ID" --warp "$PERSONAL_GHOSTTY_WINDOW_ID"
  yabai -m window "$CHATGPT_WINDOW_ID" --insert south
  yabai -m window "$OBSIDIAN_WINDOW_ID" --warp "$CHATGPT_WINDOW_ID"
fi

yabai -m window "$PERSONAL_GHOSTTY_WINDOW_ID" --ratio abs:0.50
yabai -m window "$CHATGPT_WINDOW_ID" --ratio "abs:$CHATGPT_HEIGHT_RATIO"
