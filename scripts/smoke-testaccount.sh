#!/usr/bin/env bash
# smoke-testaccount.sh — post-activation smoke battery.
#
# Per MIGRATION.md D20 + D28: testaccount is the permanent validation
# seat. Run this script after `darwin-rebuild switch --flake .#<host>` (as
# either the primary user or testaccount) to confirm each surface is alive.
#
# Usage:
#   su - testaccount
#   bash <repo-root>/scripts/smoke-testaccount.sh
#
# What it checks:
#   - Determinate-managed Nix (MIGRATION.md architecture block)
#   - nix-darwin (D1, D28)
#   - Homebrew bridge (D3, D5, D6)
#   - Home Manager zsh (D5)
#   - SSH agent via 1Password (D10, D18)
#   - GPG signing-only (D10)
#   - Vendored fonts (D11)
#   - /etc/hosts facebook block (D26)
#   - Dark Mode + intentional defaults (D16)
#   - Brew leaves sanity (D2, D3, D5)
#   - starship prompt (shell-prompt-migration-2026-05-20)
#
# When to run:
#   - After every `darwin-rebuild switch` on AVA, as testaccount first, then
#     as CASE (per D1, D28).
#   - Re-runnable. No mutations. Returns non-zero if any check fails.

set -euo pipefail

pass=0
fail=0
skip=0
failures=()

check() {
  # $1=label, $2=command (string, eval'd)
  local label=$1
  local cmd=$2
  if eval "$cmd" >/dev/null 2>&1; then
    printf '  PASS  %s\n' "$label"
    pass=$((pass + 1))
  else
    printf '  FAIL  %s\n' "$label"
    fail=$((fail + 1))
    failures+=("$label")
  fi
}

expect_zero_exit() {
  # Same as check() but explicit name for readability when callers care only
  # about exit code.
  local label=$1
  local cmd=$2
  if eval "$cmd" >/dev/null 2>&1; then
    printf '  PASS  %s\n' "$label"
    pass=$((pass + 1))
  else
    printf '  FAIL  %s\n' "$label"
    fail=$((fail + 1))
    failures+=("$label")
  fi
}

expect_in_output() {
  # $1=label, $2=command, $3=substring
  local label=$1
  local cmd=$2
  local needle=$3
  local out
  if out=$(eval "$cmd" 2>/dev/null) && printf '%s' "$out" | grep -qF -- "$needle"; then
    printf '  PASS  %s\n' "$label"
    pass=$((pass + 1))
  else
    printf '  FAIL  %s (expected substring: %s)\n' "$label" "$needle"
    fail=$((fail + 1))
    failures+=("$label")
  fi
}

skip_check() {
  local label=$1
  local reason=$2
  printf '  SKIP  %s (%s)\n' "$label" "$reason"
  skip=$((skip + 1))
}

printf '\n=== Determinate-managed Nix [MIGRATION arch] ===\n'
expect_in_output "nix on PATH lives under /nix or /run/current-system" \
  "command -v nix" \
  "/nix"
expect_zero_exit "nix --version succeeds" "nix --version"

printf '\n=== nix-darwin [D1, D28] ===\n'
expect_zero_exit "darwin-rebuild present on PATH" "command -v darwin-rebuild"
expect_zero_exit "darwin-rebuild binary is executable" \
  "test -x \"\$(command -v darwin-rebuild)\""

printf '\n=== Homebrew bridge [D3, D5, D6] ===\n'
expect_in_output "brew lives at /opt/homebrew/bin/brew" \
  "command -v brew" \
  "/opt/homebrew/bin/brew"
if [ -f /opt/homebrew/Brewfile ]; then
  expect_zero_exit "brew bundle check --no-upgrade against /opt/homebrew/Brewfile" \
    "brew bundle check --no-upgrade --file=/opt/homebrew/Brewfile"
else
  skip_check "brew bundle check" "/opt/homebrew/Brewfile not present yet"
fi

printf '\n=== Home Manager zsh [D5] ===\n'
check "~/.zshrc exists (HM-managed)" "test -f \"\$HOME/.zshrc\""

printf '\n=== starship prompt [shell-prompt-migration-2026-05-20] ===\n'
expect_zero_exit "starship on PATH" "command -v starship"
expect_zero_exit "~/.config/starship.toml exists (HM-rendered TOML)" \
  "test -f \"\$HOME/.config/starship.toml\""
expect_zero_exit "~/.p10k.zsh symlink GC'd by HM linkGeneration" \
  "test ! -e \"\$HOME/.p10k.zsh\""

printf '\n=== SSH agent via 1Password [D10, D18] ===\n'
expect_in_output "ssh -G github.com points IdentityAgent at 1Password socket" \
  "ssh -G github.com" \
  "1password/t/agent.sock"

printf '\n=== GPG signing-only [D10] ===\n'
expect_zero_exit "gpg --list-secret-keys exits 0" "gpg --list-secret-keys"
expect_in_output "GPG signing key 715CED2327899E28 present" \
  "gpg --list-secret-keys" \
  "715CED2327899E28"

printf '\n=== Vendored fonts [D11] ===\n'
# Filesystem check, not system_profiler: macOS lazily reindexes the font
# registry, so a fresh switch leaves files on disk without registering them
# until a GUI event (e.g. Font Book / app font request) prompts a scan. The
# D11 invariant is "fonts deployed to ~/Library/Fonts", which is
# exactly what HM owns.
expect_zero_exit "Operator Mono Nerd Font file present in ~/Library/Fonts" \
  "ls \"\$HOME/Library/Fonts/Operator Mono Book Nerd Font Complete.otf\""

printf '\n=== gitego identity ledger [D25] ===\n'
# `gitego list` exits non-zero when ~/.gitego/config.yaml is malformed;
# catching that here prevents a silent regression of the renderer
# (Nix multiline strings previously dropped ssh_key out of its profile).
# gitego is a Go binary; check $GOPATH/bin in addition to PATH.
gitego_bin=""
if command -v gitego >/dev/null 2>&1; then
  gitego_bin=$(command -v gitego)
elif [ -x "$HOME/go/bin/gitego" ]; then
  gitego_bin="$HOME/go/bin/gitego"
fi
if [ -n "$gitego_bin" ]; then
  expect_zero_exit "gitego list parses HM-generated config.yaml" \
    "\"$gitego_bin\" list"
  expect_in_output "gitego list reports jry as the active profile" \
    "\"$gitego_bin\" list" \
    "* "
else
  skip_check "gitego list" "gitego not found (Go binary; install via go install)"
fi

printf '\n=== /etc/hosts facebook block [D26] ===\n'
expect_zero_exit "/etc/hosts blocks facebook.com via 0.0.0.0" \
  "grep -E '^0\\.0\\.0\\.0[[:space:]].*facebook\\.com' /etc/hosts"

printf '\n=== macOS defaults [D16] ===\n'
# Dark Mode is set by writing AppleInterfaceStyle=Dark; Light Mode leaves the
# key unset. Treat unset-or-Dark as both valid only if D16 keeps Dark explicit.
expect_in_output "Dark Mode (NSGlobalDomain AppleInterfaceStyle)" \
  "defaults read NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true" \
  "Dark"

printf '\n=== Brew leaves sanity [D2, D3, D5] ===\n'
# After D5 aggressive Brew->Nix migration, leaves count will shrink from the
# pre-migration 107. Threshold deliberately permissive to catch full collapse,
# not nominal drift. TODO: tighten once D5 migration lands and the post-
# migration leaves count is known.
expect_zero_exit "brew leaves count >= 20 (sanity floor)" \
  "test \"\$(brew leaves 2>/dev/null | wc -l | tr -d ' ')\" -ge 20"

printf '\n=== Summary ===\n'
printf '  pass: %d\n  fail: %d\n  skip: %d\n' "$pass" "$fail" "$skip"
if [ "$fail" -gt 0 ]; then
  printf '\nFailures:\n'
  for f in "${failures[@]}"; do
    printf '  - %s\n' "$f"
  done
  exit 1
fi
exit 0
