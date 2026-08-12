#!/usr/bin/env bash
# Measure startup time and compare against the committed lvim baseline.
#
#   tests/startuptime.sh measure <appname|lvim> <runs>   -> prints median ms
#   tests/startuptime.sh baseline                        -> writes the lvim baseline
#   tests/startuptime.sh check                           -> fails if slower than baseline x TOLERANCE
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASELINE="$HERE/baseline/lvim-startuptime.txt"
TOLERANCE="${STARTUP_TOLERANCE:-1.2}"
RUNS="${STARTUP_RUNS:-5}"

# Median of N runs of the last line of --startuptime, which is the total.
measure() {
  local target="$1" runs="$2" out times=()
  out="$(mktemp -d)"
  trap 'rm -rf "$out"' RETURN
  for i in $(seq 1 "$runs"); do
    local log="$out/run$i.log"
    if [[ "$target" == "lvim" ]]; then
      lvim --headless --startuptime "$log" +qa >/dev/null 2>&1 || true
    else
      NVIM_APPNAME="$target" nvim --headless --startuptime "$log" +qa >/dev/null 2>&1 || true
    fi
    times+=("$(awk '/--- NVIM STARTED ---/ {print $1}' "$log" | tail -1)")
  done
  printf '%s\n' "${times[@]}" | sort -n | awk '{a[NR]=$1} END {print (NR%2==1) ? a[(NR+1)/2] : (a[NR/2]+a[NR/2+1])/2}'
}

case "${1:-check}" in
  measure)
    measure "${2:?appname}" "${3:-$RUNS}"
    ;;
  baseline)
    mkdir -p "$(dirname "$BASELINE")"
    ms="$(measure lvim "$RUNS")"
    printf '%s\n' "$ms" > "$BASELINE"
    echo "lvim baseline: ${ms}ms (median of $RUNS)"
    ;;
  check)
    if [[ ! -f "$BASELINE" ]]; then
      echo "no baseline at $BASELINE — run 'task test:startup:baseline'" >&2
      exit 1
    fi
    base="$(cat "$BASELINE")"
    got="$(measure nvim-lazy "$RUNS")"
    limit="$(awk -v b="$base" -v t="$TOLERANCE" 'BEGIN {printf "%.1f", b*t}')"
    if awk -v g="$got" -v l="$limit" 'BEGIN {exit !(g > l)}'; then
      echo "FAIL startup: ${got}ms > ${limit}ms (lvim baseline ${base}ms x $TOLERANCE)"
      exit 1
    fi
    echo "ok   startup: ${got}ms <= ${limit}ms (lvim baseline ${base}ms x $TOLERANCE)"
    ;;
  *)
    echo "usage: $0 {measure <target> [runs]|baseline|check}" >&2
    exit 2
    ;;
esac
