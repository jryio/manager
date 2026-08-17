#!/bin/zsh
set -euo pipefail

repo_root=${0:A:h:h}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/speak-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/home/.config/speak"

cp "$repo_root/modules/home-manager/assets/speak/kyutai-tts.py" "$tmpdir/home/.config/speak/kyutai-tts.py"
cp "$repo_root/modules/home-manager/assets/speak/speak-verify.py" "$tmpdir/home/.config/speak/speak-verify.py"

cat > "$tmpdir/bin/gum" <<'EOF'
#!/bin/zsh
case "$1" in
  choose)
    shift
    while (( $# )); do
      [[ "$1" == --header ]] && { shift 2; continue; }
      case "$1" in
        'Play now'|'Save WAV…') print -r -- 'Play now'; return 0 ;;
      esac
      shift
    done
    return 1
    ;;
  table) cat ;;
  style) print -r -- "${*: -1}" ;;
  write) print -r -- 'Interactive text' ;;
  input) print -r -- "${GUM_INPUT_VALUE:-/tmp/out.wav}" ;;
esac
EOF

cat > "$tmpdir/bin/uv" <<'EOF'
#!/bin/zsh
print -r -- "uv:$*" >> "$SPEAK_TEST_LOG"
[[ "$1" == run && "$2" == --script ]] || exit 64
script="$3"
shift 3
if [[ "$script" == *kyutai-tts.py ]]; then
  inp="$1" out="$2"
  shift 2
  if [[ "$inp" == - ]]; then
    print -r -- "stdin:$(cat)" >> "$SPEAK_TEST_LOG"
  fi
  printf 'RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x40\x1F\x00\x00\x40\x1F\x00\x00\x01\x00\x08\x00data\x00\x00\x00\x00' > "$out"
  while (( $# )); do
    [[ "$1" == --report ]] && print -r -- '{"chunks": []}' > "$2"
    shift
  done
elif [[ "$script" == *speak-verify.py ]]; then
  print -r -- 'PASS'
fi
EOF

cat > "$tmpdir/bin/afplay-log" <<'EOF'
#!/bin/zsh
EOF
chmod +x "$tmpdir/bin/gum" "$tmpdir/bin/uv" "$tmpdir/bin/afplay-log"

export HOME="$tmpdir/home"
export XDG_CONFIG_HOME="$tmpdir/home/.config"
export XDG_STATE_HOME="$tmpdir/home/.local/state"
export PATH="$tmpdir/bin:$PATH"
export SPEAK_TEST_LOG="$tmpdir/commands.log"
: > "$SPEAK_TEST_LOG"
source "$repo_root/modules/home-manager/shell/kyutai-tts.zsh"

# afplay is invoked by absolute path; stub it out for the test.
_speak_play_real=$(functions _speak_play)
eval "${_speak_play_real/\/usr\/bin\/afplay/afplay-log}"

speak 'Hello Kyutai'
[[ "$(<"$SPEAK_TEST_LOG")" == *'kyutai-tts.py - '* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'--voice expresso/ex03-ex01_happy_001_channel1_334s.wav'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--quantize'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'stdin:Hello Kyutai'* ]]

: > "$SPEAK_TEST_LOG"
print -r -- 'Piped Kyutai' | speak
[[ "$(<"$SPEAK_TEST_LOG")" == *'stdin:Piped Kyutai'* ]]

# Pocket-era settings (v2) must be discarded, not mapped.
mkdir -p "$XDG_STATE_HOME/speak"
cat > "$XDG_STATE_HOME/speak/settings" <<'EOF'
settings_version	2
voice	alba
max_tokens	300
EOF
: > "$SPEAK_TEST_LOG"
speak 'Migrated'
[[ "$(<"$SPEAK_TEST_LOG")" == *'--voice expresso/ex03-ex01_happy_001_channel1_334s.wav'* ]]
[[ "$(<"$XDG_STATE_HOME/speak/settings")" == *$'settings_version\t3'* ]]
[[ "$(<"$XDG_STATE_HOME/speak/settings")" != *max_tokens* ]]

cat > "$XDG_STATE_HOME/speak/settings" <<'EOF'
settings_version	3
voice	alba-mackenna/casual.wav
quantize	8
EOF
: > "$SPEAK_TEST_LOG"
speak 'Configured'
[[ "$(<"$SPEAK_TEST_LOG")" == *'--voice alba-mackenna/casual.wav'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'--quantize 8'* ]]

speak generate 'Choose audio'
speak settings show > "$tmpdir/settings.txt"
[[ "$(<"$tmpdir/settings.txt")" == *$'Voice\talba-mackenna/casual.wav'* ]]
[[ "$(<"$tmpdir/settings.txt")" == *$'Quantize\t8'* ]]

: > "$SPEAK_TEST_LOG"
verify_output=$(speak verify 'Check me')
[[ "$verify_output" == *PASS* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'--report'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'speak-verify.py'* ]]

# Normalizer regression: markdown, currency, ranges, acronym-safe splits.
if command -v python3 >/dev/null 2>&1; then
  normalized=$(print -r -- 'CloudX reached **$20,000 to $22,000** per day (25% of $80,000), CPMs 3-5x GAM. See CXD-3190 at 23:42.' | \
    python3 "$repo_root/modules/home-manager/assets/speak/kyutai-tts.py" - /dev/null --normalize-only)
  [[ "$normalized" == *'twenty thousand dollars to twenty two thousand dollars'* ]]
  [[ "$normalized" == *'twenty five percent of eighty thousand dollars'* ]]
  [[ "$normalized" == *'three to five x GAM'* ]]
  [[ "$normalized" == *'twenty three forty two'* ]]
  [[ "$normalized" != *'$'* ]]
fi

print -r -- 'speak wrapper: PASS'
