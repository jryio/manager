# Kyutai TTS (MLX) is invoked only through speak; uv owns its isolated
# Python environment. The generator script lives in ~/.config/speak/ and is
# managed by Home Manager (modules/home-manager/assets/speak/).

_speak_defaults() {
  typeset -gA speak_config

  speak_config=(
    settings_version 3
    voice expresso/ex03-ex01_happy_001_channel1_334s.wav
    quantize off
  )
}

_speak_settings_file() {
  print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/speak/settings"
}

_speak_script_dir() {
  print -r -- "${XDG_CONFIG_HOME:-$HOME/.config}/speak"
}

_speak_load_settings() {
  local settings_file key value settings_version=''

  settings_file="$(_speak_settings_file)"
  [[ -r "$settings_file" ]] || return 0

  while IFS=$'\t' read -r key value; do
    (( ${+speak_config[$key]} )) && speak_config[$key]="$value"
    [[ "$key" == settings_version ]] && settings_version="$value"
  done < "$settings_file"

  if [[ "$settings_version" != 3 ]]; then
    # Pocket TTS settings (v1/v2) do not map onto Kyutai; start fresh.
    _speak_defaults
    _speak_save_settings
  fi
}

_speak_save_settings() {
  local settings_file key

  settings_file="$(_speak_settings_file)"
  mkdir -p "${settings_file:h}" || return
  umask 077
  {
    for key in ${(ok)speak_config}; do
      printf '%s\t%s\n' "$key" "${speak_config[$key]}"
    done
  } >| "$settings_file"
}

_speak_require() {
  local command_name

  for command_name in gum uv; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      print -u2 "speak requires $command_name on PATH."
      return 69
    fi
  done
  if [[ ! -r "$(_speak_script_dir)/kyutai-tts.py" ]]; then
    print -u2 "speak: missing $(_speak_script_dir)/kyutai-tts.py; run darwin-rebuild switch."
    return 69
  fi
}

_speak_generate_args() {
  reply=(--voice "${speak_config[voice]}")
  [[ "${speak_config[quantize]}" == off ]] || reply+=(--quantize "${speak_config[quantize]}")
}

# Feed text to the generator on stdin: no shell argument limits, and Kyutai
# synthesizes sentence chunks that each stay inside the model's 40 s
# attention window (long input cannot derail the generation).
_speak_generate() {
  local text="$1" output_path="$2"
  shift 2
  local -a generate_args
  _speak_generate_args
  generate_args=("${reply[@]}")

  if [[ "$text" == - ]]; then
    uv run --script "$(_speak_script_dir)/kyutai-tts.py" - "$output_path" "${generate_args[@]}" "$@"
  else
    print -r -- "$text" | uv run --script "$(_speak_script_dir)/kyutai-tts.py" - "$output_path" "${generate_args[@]}" "$@"
  fi
}

_speak_read_text() {
  gum write --placeholder "Text to speak"
}

_speak_play() {
  local text="$1" tmpdir output_path exit_code

  if [[ "$text" != - && -z "${text//[[:space:]]/}" ]]; then
    print -u2 "speak needs text; pass an argument, pipe input, or use speak generate."
    return 64
  fi

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/speak.XXXXXX")" || return
  output_path="$tmpdir/speech.wav"
  _speak_generate "$text" "$output_path"
  exit_code=$?

  if (( exit_code == 0 )); then
    /usr/bin/afplay "$output_path"
    exit_code=$?
  fi

  rm -rf "$tmpdir"
  return "$exit_code"
}

_speak_show_settings() {
  {
    printf 'SETTING\tVALUE\n'
    printf 'Voice\t%s\n' "${speak_config[voice]}"
    printf 'Quantize\t%s\n' "${speak_config[quantize]}"
  } | gum table --print --separator=$'\t'
}

_speak_choose_voice() {
  local voice

  voice="$(gum choose --header "Kyutai TTS voice (kyutai/tts-voices)" \
    expresso/ex03-ex01_happy_001_channel1_334s.wav \
    expresso/ex03-ex01_calm_001_channel1_1143s.wav \
    expresso/ex04-ex01_narration_001_channel1_605s.wav \
    unmute-prod-website/default_voice.wav \
    unmute-prod-website/ex04_narration_longform_00001.wav \
    unmute-prod-website/p329_022.wav \
    alba-mackenna/announcer.wav \
    alba-mackenna/casual.wav \
    alba-mackenna/a-moment-by.wav \
    'Custom voice name or local safetensors…')" || return

  if [[ "$voice" == 'Custom voice name or local safetensors…' ]]; then
    voice="$(gum input --header "Voice path inside kyutai/tts-voices, or a local embedding path")" || return
  fi
  [[ -n "$voice" ]] || return 64

  speak_config[voice]="$voice"
  _speak_save_settings
}

_speak_settings() {
  local choice

  if [[ "${1:-}" == show ]]; then
    _speak_show_settings
    return
  fi
  if [[ "${1:-}" == reset ]]; then
    _speak_defaults
    _speak_save_settings
    return
  fi

  while true; do
    _speak_show_settings
    choice="$(gum choose --header "Configure speak" \
      Voice Quantization 'Reset all settings' Done)" || return
    case "$choice" in
      Voice) _speak_choose_voice ;;
      Quantization)
        choice="$(gum choose --header "Weight quantization (off = full bf16 quality)" off 8 4)" || continue
        speak_config[quantize]="$choice"
        _speak_save_settings
        ;;
      'Reset all settings') _speak_defaults; _speak_save_settings ;;
      Done) return ;;
    esac
  done
}

_speak_generate_interactive() {
  local text="$1" destination output_path

  if [[ -z "$text" ]]; then
    if [[ -t 0 ]]; then
      text="$(_speak_read_text)" || return
    else
      text=-
    fi
  fi
  if [[ "$text" != - && -z "${text//[[:space:]]/}" ]]; then
    return 64
  fi

  destination="$(gum choose --header "Generated audio" 'Play now' 'Save WAV…')" || return
  if [[ "$destination" == 'Play now' ]]; then
    _speak_play "$text"
    return
  fi

  output_path="$(gum input --header "WAV output path" --value "$PWD/tts_output.wav")" || return
  [[ -n "$output_path" ]] || return 64
  _speak_generate "$text" "$output_path" --report "${output_path%.*}.report.json"
}

# ASR round-trip check: generate speech, transcribe it with Whisper (MLX),
# and fail loudly on word errors, degeneration loops, or dead air. This is
# how speak output is validated without listening to it.
_speak_verify() {
  local text="$1" tmpdir exit_code

  if [[ "$text" != - && -z "${text//[[:space:]]/}" ]]; then
    print -u2 "speak verify needs text; pass an argument or pipe input."
    return 64
  fi

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/speak.XXXXXX")" || return
  _speak_generate "$text" "$tmpdir/speech.wav" --report "$tmpdir/report.json"
  exit_code=$?
  if (( exit_code == 0 )); then
    uv run --script "$(_speak_script_dir)/speak-verify.py" "$tmpdir/speech.wav" "$tmpdir/report.json"
    exit_code=$?
  fi

  rm -rf "$tmpdir"
  return "$exit_code"
}

_speak_help() {
  cat <<'EOF'
Usage:
  speak "text"             Generate and play speech.
  command | speak           Generate and play piped text.
  speak < file              Generate and play a text file.
  speak settings            Configure Kyutai TTS with Gum.
  speak settings show       Print active settings.
  speak settings reset      Restore wrapper defaults.
  speak generate [text]     Choose to play or save a WAV.
  speak verify [text]       Generate, then verify via ASR round-trip
                            (Whisper) instead of listening.
  speak -- "settings"       Speak text that is also a command name.

Speech runs on Kyutai TTS (kyutai/tts-1.6b-en_fr) under MLX. Long input is
normalized (markdown stripped, numbers expanded) and synthesized in sentence
chunks that stay inside the model's attention window, so long-form output
cannot drift off the rails. The first run downloads ~4 GB of weights.

uv owns the isolated Python environment; invoke speak, not uv.
EOF
}

speak() {
  local command="${1:-}" text

  _speak_require || return
  _speak_defaults
  _speak_load_settings

  case "$command" in
    settings)
      shift
      _speak_settings "$@"
      ;;
    generate)
      shift
      _speak_generate_interactive "$*"
      ;;
    verify)
      shift
      if (( $# )); then
        _speak_verify "$*"
      elif [[ -t 0 ]]; then
        text="$(_speak_read_text)" || return
        _speak_verify "$text"
      else
        _speak_verify -
      fi
      ;;
    help|-h|--help)
      _speak_help
      ;;
    --)
      shift
      _speak_play "$*"
      ;;
    '')
      if [[ -t 0 ]]; then
        text="$(_speak_read_text)" || return
        _speak_play "$text"
      else
        _speak_play -
      fi
      ;;
    *)
      _speak_play "$*"
      ;;
  esac
}
