#!/usr/bin/env bash
# Run one test script under the real config and report a trustworthy exit code.
#
#   tests/run.sh verify_options.lua
#
# Two traps this guards against:
#   * `nvim -l` does not load the user config, so tests must use -c luafile.
#   * with `-c luafile -c qa`, a Lua error is printed but nvim still exits 0.
#     A passing run must therefore announce itself with a HARNESS marker. The
#     marker is matched unanchored because health and treesitter output can be
#     written without a trailing newline.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${1:?usage: run.sh <script.lua>}"
export NVIM_APPNAME="${NVIM_APPNAME:-nvim-lazy}"

out="$(nvim --headless -c "luafile $HERE/$SCRIPT" -c "qa" 2>&1)"
code=$?

[ -n "$out" ] && printf '%s\n' "$out"

if [ "$code" -ne 0 ]; then
  exit "$code"
fi

if ! printf '%s\n' "$out" | grep -qE 'HARNESS (ok|skip) '; then
  printf 'FAIL %s: exited 0 without reporting a result (Lua error above?)\n' "$SCRIPT" >&2
  exit 1
fi
