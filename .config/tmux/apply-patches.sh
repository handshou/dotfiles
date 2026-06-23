#!/usr/bin/env bash
# Re-apply local patches to tpm-managed tmux plugins. Run on tmux startup so a
# plugin update (`prefix + U`) that overwrites a plugin file gets auto-healed.
#
# Patches live in ~/.config/tmux/patches/ and are named:
#     <plugin-dir>__<description>.patch
# e.g. tmux-claude-session-manager__picker-session-titles.patch
# The part before `__` is the plugin directory under plugins/.
#
# Idempotent: a patch that already applies in reverse (i.e. is present) is
# skipped, so this is safe to run on every startup. Failures are reported but
# never block tmux from loading.
set -uo pipefail

PLUGIN_DIR="${1:-$HOME/.config/tmux/plugins}"
PATCH_DIR="$HOME/.config/tmux/patches"
[ -d "$PATCH_DIR" ] || exit 0

shopt -s nullglob
for patch in "$PATCH_DIR"/*.patch; do
  base=$(basename "$patch" .patch)
  plugin="${base%%__*}"
  target="$PLUGIN_DIR/$plugin"
  [ -d "$target" ] || continue

  # Already applied? (reverse applies cleanly) -> nothing to do.
  git -C "$target" apply --reverse --check "$patch" 2>/dev/null && continue

  # Apply forward when it fits the current file; otherwise leave a breadcrumb.
  if git -C "$target" apply --check "$patch" 2>/dev/null; then
    git -C "$target" apply "$patch" 2>/dev/null &&
      tmux display-message "tmux: applied $(basename "$patch")"
  else
    tmux display-message "tmux: could not apply $(basename "$patch") — apply manually"
  fi
done
