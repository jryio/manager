#!/usr/bin/env bash
# Assert that this config still looks like lvim, screen by screen.
#
#   tests/visual/verify.sh            # compare against the committed baselines
#   tests/visual/verify.sh --capture  # re-record the baselines from lvim
#
# Normal runs never start lvim. The baselines under baseline/ are lvim's own
# screens, captured once; comparing against them keeps working after lvim is
# uninstalled, and avoids lvim's startup 1Password prompt on every check.
#
# Colours cannot be measured headlessly -- minimal.nvim aborts with
# "&termguicolors must be set" and nvim falls back to its own palette -- so each
# screen is captured from a real terminal via tmux. See pty.sh.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE="$(dirname "$HERE")/fixtures/sample.lua"
BASELINE="$HERE/baseline"
OUT="${VIS_OUT:-${TMPDIR:-/tmp}/nvim-visual-parity}"
mkdir -p "$OUT" "$BASELINE"

# name | file ("-" for none) | keys sent once the editor has settled
#
# The command line is deliberately absent: lvim prints a transient LSP
# deprecation warning over that row, which makes an unstable baseline. Its
# position is asserted instead by `cmdheight` in tests/verify_options.lua.
SCENARIOS=(
  "open|$FIXTURE|"
  "insert|$FIXTURE|i"
  "visual|$FIXTURE|v j l"
  "modified|$FIXTURE|i x Escape"
  "dashboard|-|"
)

capture() {
  local editor="$1" name="$2" file="$3" out="$4"
  shift 4
  # Priming presses Enter to clear a hit-enter prompt, which on a start screen
  # would press a button instead.
  local no_prime=0
  [ "$name" = "dashboard" ] && [ "$editor" = "lazyvim" ] && no_prime=1
  # shellcheck disable=SC2086
  VIS_NO_PRIME="$no_prime" VIS_SETTLE="${VIS_SETTLE:-15}" \
    VIS_STUB_OP="$([ "$editor" = lvim ] && echo 1 || echo 0)" \
    bash "$HERE/pty.sh" shot "$editor" "$out" "$file" $* >/dev/null 2>&1
}

if [ "${1:-}" = "--capture" ]; then
  if ! command -v lvim >/dev/null 2>&1; then
    printf 'cannot capture: lvim is not installed\n' >&2
    exit 1
  fi
  for entry in "${SCENARIOS[@]}"; do
    IFS='|' read -r name file keys <<<"$entry"
    capture lvim "$name" "$file" "$BASELINE/$name.ansi" $keys
    printf '  recorded %s\n' "$name"
  done
  printf 'baselines written to %s\n' "$BASELINE"
  exit 0
fi

fail=0
pass=0

for entry in "${SCENARIOS[@]}"; do
  IFS='|' read -r name file keys <<<"$entry"

  if [ ! -s "$BASELINE/$name.ansi" ]; then
    printf '  skip %-10s no baseline; run verify.sh --capture while lvim exists\n' "$name"
    continue
  fi

  capture lazyvim "$name" "$file" "$OUT/$name.ansi" $keys

  report="$(python3 "$HERE/screen.py" diff "$BASELINE/$name.ansi" "$OUT/$name.ansi")"
  if printf '%s' "$report" | grep -q 'no colour differences' &&
    ! printf '%s' "$report" | grep -q 'rows differ in text'; then
    printf '  ok   %-10s identical to lvim\n' "$name"
    pass=$((pass + 1))
  else
    printf '  FAIL %-10s\n%s\n' "$name" "$report"
    fail=$((fail + 1))
  fi
done

if [ "$fail" -gt 0 ]; then
  printf 'HARNESS FAIL visual: %d of %d screens differ (captures in %s)\n' "$fail" "$((fail + pass))" "$OUT"
  exit 1
fi

printf 'HARNESS ok   visual: %d screens pixel-identical to lvim\n' "$pass"
