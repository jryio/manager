#!/bin/zsh
set -euo pipefail

repo_root=${0:A:h:h}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/speak-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/home"

cat > "$tmpdir/bin/gum" <<'EOF'
#!/bin/zsh
case "$1" in
  spin)
    shift
    while (( $# )); do
      case "$1" in
        --title) shift 2 ;;
        --) shift; break ;;
        --*) shift ;;
        *) break ;;
      esac
    done
    print -r -- "command:$*" >> "$SPEAK_TEST_LOG"
    "$@"
    ;;
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
  input) print -r -- "${GUM_INPUT_VALUE:-/tmp/exported.safetensors}" ;;
  file) print -r -- /tmp/voice.wav ;;
esac
EOF

cat > "$tmpdir/bin/uvx" <<'EOF'
#!/bin/zsh
print -r -- "uvx:$*" >> "$SPEAK_TEST_LOG"
while (( $# )); do
  if [[ "$1" == --output-path ]]; then
    printf 'RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x40\x1F\x00\x00\x40\x1F\x00\x00\x01\x00\x08\x00data\x00\x00\x00\x00' > "$2"
    break
  fi
  shift
done
EOF
chmod +x "$tmpdir/bin/gum" "$tmpdir/bin/uvx"


export HOME="$tmpdir/home"
export PATH="$tmpdir/bin:$PATH"
export SPEAK_TEST_LOG="$tmpdir/commands.log"
source "$repo_root/modules/home-manager/shell/pocket-tts.zsh"

speak 'Hello Pocket'
[[ "$(<"$SPEAK_TEST_LOG")" != *'--lsd-decode-steps'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--noise-clamp'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--eos-threshold'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--frames-after-eos'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--max-tokens'* ]]

print -r -- 'Piped Pocket' | speak
[[ "$(<"$SPEAK_TEST_LOG")" == *'pocket-tts generate --text Piped Pocket'* ]]

mkdir -p "$HOME/.local/state/speak"
cat > "$HOME/.local/state/speak/settings" <<'EOF'
max_tokens	300
noise_clamp	1.0
eos_threshold	0.5
EOF
: > "$SPEAK_TEST_LOG"
speak 'Migrated Pocket'
[[ "$(<"$SPEAK_TEST_LOG")" != *'--max-tokens 300'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--noise-clamp 1.0'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--eos-threshold 0.5'* ]]
[[ "$(<"$HOME/.local/state/speak/settings")" == *$'settings_version\t2'* ]]

cat > "$HOME/.local/state/speak/settings" <<'EOF'
settings_version	2
config	/opt/pocket/custom.yaml
quantize	true
temperature	0.7
server_host	127.0.0.1
server_port	9000
server_reload	true
EOF
: > "$SPEAK_TEST_LOG"

speak 'Configured Pocket'
[[ "$(<"$SPEAK_TEST_LOG")" == *'--config /opt/pocket/custom.yaml'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" != *'--language english'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'--temperature 0.7'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'--quantize'* ]]

speak generate 'Choose audio'
speak serve
speak export-voice /tmp/voice.wav /tmp/voice.safetensors
speak settings show > "$tmpdir/settings.txt"

[[ "$(<"$SPEAK_TEST_LOG")" == *'pocket-tts serve --host 127.0.0.1 --port 9000 --config /opt/pocket/custom.yaml --reload --quantize'* ]]
[[ "$(<"$SPEAK_TEST_LOG")" == *'pocket-tts export-voice /tmp/voice.wav /tmp/voice.safetensors --config /opt/pocket/custom.yaml'* ]]
[[ "$(<"$tmpdir/settings.txt")" == *$'Voice\talba'* ]]

print -r -- 'speak wrapper: PASS'
