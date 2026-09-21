#!/usr/bin/env bash
# Exercise the configured Neovim in a pseudo-terminal long enough for delayed
# User VeryLazy handlers and native plugins to load.
set -uo pipefail

seconds="${NVIM_LAUNCH_SECONDS:-5}"
out="$(NVIM_LAUNCH_SECONDS="$seconds" script -q /dev/null nvim \
  '+doautocmd User VeryLazy' \
  '+lua vim.wait((tonumber(vim.env.NVIM_LAUNCH_SECONDS) or 5) * 1000, function() return false end)' \
  +qa 2>&1)"
code=$?

[ -n "$out" ] && printf '%s\n' "$out"

if [ "$code" -ne 0 ]; then
  printf 'FAIL terminal startup: nvim exited %d before %ss\n' "$code" "$seconds" >&2
  exit "$code"
fi

printf 'HARNESS ok   terminal startup: survived %ss with VeryLazy\n' "$seconds"
