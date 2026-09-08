#!/usr/bin/env bash
# vim-tmux-navigator style smart pane navigation for Herdr.
#
# Bound directly to ctrl+h/j/k/l (see [[keys.command]] in config.toml).
# If the focused pane's foreground process looks like vim/view/fzf, forward
# the same chord into the pane so vim-tmux-navigator (or plain vim wincmd)
# can handle it, including bouncing back out to Herdr via the tmux shim at
# split edges. Otherwise move focus between Herdr panes directly.

set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
dir="${1:-}"
log="${HERDR_PLUGIN_STATE_DIR:-/tmp}/nav.log"

case "$dir" in
  left) key="ctrl+h" ;;
  down) key="ctrl+j" ;;
  up) key="ctrl+k" ;;
  right) key="ctrl+l" ;;
  *)
    echo "usage: nav.sh <left|down|up|right>" >&2
    exit 2
    ;;
esac

pane_id="${HERDR_PANE_ID:-}"
if [[ -z "$pane_id" ]]; then
  ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
  if [[ -n "$ctx" ]] && command -v jq >/dev/null 2>&1; then
    pane_id="$(printf '%s' "$ctx" | jq -r '.focused_pane.pane_id // .pane.pane_id // empty' 2>/dev/null || true)"
  fi
fi

if [[ -z "$pane_id" ]]; then
  # No pane context available; fall back to plain focus move.
  exec "$herdr" pane focus --direction "$dir" --current
fi

fg_name=""
if info_json="$("$herdr" pane process-info --pane "$pane_id" 2>/dev/null)"; then
  if command -v jq >/dev/null 2>&1; then
    fg_name="$(printf '%s' "$info_json" | jq -r '.result.process_info.foreground_processes[-1].name // ""')"
  fi
fi

echo "$(date -Is) dir=$dir pane=$pane_id fg=$fg_name" >>"$log" 2>/dev/null || true

if [[ "$fg_name" =~ ^g?\.?(view|n?vim|vimx|nvimx|fzf)(diff)?(-wrapped)?$ ]]; then
  exec "$herdr" pane send-keys "$pane_id" "$key"
else
  exec "$herdr" pane focus --direction "$dir" --pane "$pane_id"
fi
