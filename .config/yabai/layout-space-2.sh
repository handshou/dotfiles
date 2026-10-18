#!/bin/sh

# Restore the Space 2 BSP layout after its windows exist and the space is visible.
set -eu

TARGET_SPACE_INDEX=2
CHATGPT_WIDTH_RATIO=0.20
# Ghostty gets 75% of the remaining 80%: 60% of the total width.
GHOSTTY_REMAINING_WIDTH_RATIO=0.75
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
  $chatgpt_window["split-type"] == "vertical" and
  $chatgpt_window["split-child"] == "first_child" and
  $ghostty_window["split-type"] == "vertical" and
  $ghostty_window["split-child"] == "first_child" and
  $obsidian_window["split-type"] == "vertical" and
  $obsidian_window["split-child"] == "second_child" and
  $chatgpt_window.frame.x < $ghostty_window.frame.x and
  $ghostty_window.frame.x < $obsidian_window.frame.x and
  $chatgpt_window.frame.y == $ghostty_window.frame.y and
  $ghostty_window.frame.y == $obsidian_window.frame.y
')

# Three full-height columns: ChatGPT 20% | Ghostty 60% | Obsidian 20%.
# Warping existing siblings can preserve the wrong BSP topology. Detach the
# two right-hand windows first, then reinsert them into a known tree.
# ChatGPT reports a slightly different frame height, so compare top edges
# rather than requiring identical app-reported heights above.
if [ "$LAYOUT_IS_ALREADY_NESTED" != "true" ]; then
  for WINDOW_ID in "$PERSONAL_GHOSTTY_WINDOW_ID" "$OBSIDIAN_WINDOW_ID"; do
    IS_FLOATING=$(yabai -m query --windows --window "$WINDOW_ID" | jq -r '."is-floating"')
    if [ "$IS_FLOATING" != "true" ]; then
      yabai -m window "$WINDOW_ID" --toggle float
    fi
  done
  # --insert toggles off when repeated; a different direction first ensures east.
  yabai -m window "$CHATGPT_WINDOW_ID" --insert south
  yabai -m window "$CHATGPT_WINDOW_ID" --insert east
  yabai -m window "$PERSONAL_GHOSTTY_WINDOW_ID" --toggle float
  yabai -m window "$PERSONAL_GHOSTTY_WINDOW_ID" --insert south
  yabai -m window "$PERSONAL_GHOSTTY_WINDOW_ID" --insert east
  yabai -m window "$OBSIDIAN_WINDOW_ID" --toggle float
fi

yabai -m window "$CHATGPT_WINDOW_ID" --ratio "abs:$CHATGPT_WIDTH_RATIO"
yabai -m window "$PERSONAL_GHOSTTY_WINDOW_ID" --ratio "abs:$GHOSTTY_REMAINING_WIDTH_RATIO"
