#!/usr/bin/env bash
# server-ledger — append-only, hash-chained record of every machine change.
#
#   server-ledger <category> <message...>   append one entry
#   server-ledger --verify                  re-check the whole hash chain
#   server-ledger --show                    print the ledger
#
# The file carries the kernel `sappnd` flag (set by nix-darwin activation in
# modules/darwin/server.nix): it can only be appended to; edits, truncation,
# deletion and rename fail until root clears the flag. Each entry ends with
# the first 16 hex chars of sha256(previous line), so any after-the-fact edit
# made by clearing the flag breaks --verify from that line on.
set -euo pipefail

LEDGER="${SERVER_LEDGER:-$HOME/Library/Logs/server-ledger.log}"
GENESIS="genesis"

hash_line() { printf '%s' "$1" | shasum -a 256 | cut -c1-16; }

verify() {
  local prev="$GENESIS" n=0 bad=0 line want got
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    [ -z "$line" ] && continue
    case "$line" in \#*) prev=$(hash_line "$line"); continue ;; esac
    got=${line##* prev=}
    if [ "$prev" = "$GENESIS" ]; then want=$GENESIS; else want=$prev; fi
    if [ "$got" != "$want" ]; then
      echo "BROKEN at line $n: expected prev=$want, found prev=$got" >&2
      bad=1
    fi
    prev=$(hash_line "$line")
  done <"$LEDGER"
  ls -lO "$LEDGER" | grep -q sappnd || { echo "WARNING: sappnd flag missing on $LEDGER" >&2; bad=1; }
  [ $bad = 0 ] && echo "ledger OK: $n lines, chain intact, sappnd set"
  return $bad
}

case "${1:-}" in
  --verify) verify ;;
  --show) cat "$LEDGER" ;;
  "" | -h | --help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//' ;;
  *)
    [ $# -ge 2 ] || { echo "usage: server-ledger <category> <message...>" >&2; exit 2; }
    cat="$1"; shift
    last=$(tail -n 1 "$LEDGER" 2>/dev/null || true)
    if [ -z "$last" ]; then prev=$GENESIS; else prev=$(hash_line "$last"); fi
    printf '%s | %-11s | %s | prev=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$cat" "$*" "$prev" >>"$LEDGER"
    ;;
esac
