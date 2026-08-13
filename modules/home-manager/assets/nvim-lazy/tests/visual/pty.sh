#!/usr/bin/env bash
# Run an editor inside a real pty and take an ANSI screenshot of it.
#
#   tests/visual/pty.sh shot   <lvim|lazyvim> <out.ansi> [file] [keys...]
#   tests/visual/pty.sh dump   <lvim|lazyvim> <out.json> [file]
#
# Neither editor loads its colourscheme headlessly -- minimal.nvim aborts with
# "&termguicolors must be set" -- so every colour measurement has to come from a
# terminal. tmux is that terminal: fixed size, 24-bit colour forced on, and
# `capture-pane -e` gives back the SGR sequences the editor actually emitted.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS="$(dirname "$HERE")"
CONFIG="$(dirname "$TESTS")"

COLS="${VIS_COLS:-120}"
ROWS="${VIS_ROWS:-40}"
SETTLE="${VIS_SETTLE:-6}"

mode="${1:?usage: pty.sh <shot|dump> <editor> <out> [file] [keys...]}"
editor="${2:?editor}"
out="${3:?out}"
file="${4:-$TESTS/fixtures/sample.lua}"
shift 4 2>/dev/null || shift $#

case "$editor" in
  lvim) cmd="lvim" ;;
  lazyvim) cmd="lazyvim" ;;
  *) echo "unknown editor: $editor" >&2; exit 2 ;;
esac

# A stale file from a previous run would otherwise be mistaken for this one's.
rm -f "$out"

session="vis-$editor-$$"
# A throwaway server (-L) with no user config (-f /dev/null) keeps the operator's
# tmux untouched, and RGB is declared explicitly so capture-pane reports true
# 24-bit colour instead of the nearest 256 index.
tm() { tmux -L "$session" -f /dev/null "$@"; }

cleanup() { tm kill-server 2>/dev/null || true; }
trap cleanup EXIT

# `-n` disables the swap file. Without it, a session killed mid-capture leaves a
# swap behind and the next run opens the fixture read-only, which shows up as a
# spurious [RO] in the statusline.
#
# `-` means "start with no file at all", which is how the dashboard is reached.
# An empty argument is not the same thing: nvim reads it as a path and opens a
# directory listing for the working directory.
if [ "$file" = "-" ]; then
  launch="$cmd -n"
else
  launch="$cmd -n $(printf '%q' "$file")"
fi

# lvim's avante block runs `op item get` against a vault that no longer exists,
# so every single start pops a 1Password prompt. Only baseline capture runs lvim,
# and a stub that fails immediately keeps 1Password out of it -- the key lookup
# was already failing, so nothing about lvim's appearance changes.
if [ "${VIS_STUB_OP:-0}" = "1" ]; then
  stub="$(mktemp -d)"
  printf '#!/bin/sh\nexit 1\n' >"$stub/op"
  chmod +x "$stub/op"
  launch="env PATH=$stub:\$PATH $launch"
fi

tm new-session -d -x "$COLS" -y "$ROWS" -s main \
  -e "NVIM_DUMP_OUT=$out" -e "TERM=xterm-256color" \
  "$launch"
tm set-option -g default-terminal tmux-256color
tm set-option -g terminal-features ',*:RGB'
tm set-option -g status off

sleep "$SETTLE"

case "$mode" in
  shot)
    # Clear any hit-enter prompt (lvim boots into a screenful of avante
    # deprecation warnings) so the shot shows the editor, not its startup log.
    # VIS_NO_PRIME=1 for the dashboard, where Enter would press a button and
    # `gg` is meaningless.
    if [ "${VIS_NO_PRIME:-0}" != "1" ]; then
      tm send-keys -t main Enter
      sleep 1
      tm send-keys -t main Escape
      # Same shada-restored cursor as the dump path: park it on line 1 so the
      # winbar breadcrumb and the statusline's position agree between editors.
      tm send-keys -t main "gg"
    fi
    sleep 2
    for keys in "$@"; do
      tm send-keys -t main "$keys"
      sleep 1
    done
    sleep 1
    tm capture-pane -t main -p -e > "$out"
    ;;
  dump)
    tm send-keys -t main Escape
    # Both editors restore the last cursor position from shada, which would
    # otherwise show up as a statusline difference (`1:1` against `2:1`).
    tm send-keys -t main "gg"
    sleep 1
    tm send-keys -t main ":luafile $TESTS/dump_visual.lua" Enter
    for _ in $(seq 1 30); do
      [ -s "$out" ] && break
      sleep 1
    done
    [ -s "$out" ] || { echo "dump produced nothing for $editor" >&2; exit 1; }
    ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac

printf 'captured %s %s -> %s\n' "$mode" "$editor" "$out"
