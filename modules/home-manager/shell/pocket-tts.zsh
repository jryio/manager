# Pocket TTS is invoked only through speak; uvx owns its isolated Python environment.

_speak_defaults() {
  typeset -gA speak_config

  speak_config=(
    settings_version 2
    voice alba
    language english
    config ''
    device cpu
    quantize false
    lsd_decode_steps ''
    temperature ''
    noise_clamp ''
    eos_threshold ''
    frames_after_eos ''
    max_tokens ''
    server_host localhost
    server_port 8000
    server_reload false
  )
}

_speak_reset_generation_settings() {
  speak_config[lsd_decode_steps]=''
  speak_config[temperature]=''
  speak_config[noise_clamp]=''
  speak_config[eos_threshold]=''
  speak_config[frames_after_eos]=''
  speak_config[max_tokens]=''
}

_speak_settings_file() {
  print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/speak/settings"
}

_speak_load_settings() {
  local settings_file key value settings_version='' migrated=false

  settings_file="$(_speak_settings_file)"
  [[ -r "$settings_file" ]] || return 0

  while IFS=$'\t' read -r key value; do
    (( ${+speak_config[$key]} )) && speak_config[$key]="$value"
    [[ "$key" == settings_version ]] && settings_version="$value"
  done < "$settings_file"

  if [[ "$settings_version" != 2 ]]; then
    _speak_reset_generation_settings
    speak_config[settings_version]=2
    migrated=true
  fi
  if [[ "$migrated" == true ]]; then
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

  for command_name in gum uvx; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      print -u2 "speak requires $command_name on PATH."
      return 69
    fi
  done
}

_speak_model_args() {
  reply=()

  if [[ -n "${speak_config[config]}" ]]; then
    reply+=(--config "${speak_config[config]}")
  else
    reply+=(--language "${speak_config[language]}")
  fi
}

_speak_generate() {
  local text="$1" output_path="$2"
  local -a command model_args

  _speak_model_args
  model_args=("${reply[@]}")
  command=(
    uvx pocket-tts generate
    --text "$text"
    --voice "${speak_config[voice]}"
    "${model_args[@]}"
    --device "${speak_config[device]}"
    --output-path "$output_path"
  )

  [[ -n "${speak_config[lsd_decode_steps]}" ]] && command+=(--lsd-decode-steps "${speak_config[lsd_decode_steps]}")
  [[ -n "${speak_config[temperature]}" ]] && command+=(--temperature "${speak_config[temperature]}")
  [[ -n "${speak_config[noise_clamp]}" ]] && command+=(--noise-clamp "${speak_config[noise_clamp]}")
  [[ -n "${speak_config[eos_threshold]}" ]] && command+=(--eos-threshold "${speak_config[eos_threshold]}")
  [[ -n "${speak_config[frames_after_eos]}" ]] && command+=(--frames-after-eos "${speak_config[frames_after_eos]}")
  [[ -n "${speak_config[max_tokens]}" ]] && command+=(--max-tokens "${speak_config[max_tokens]}")
  [[ "${speak_config[quantize]}" == true ]] && command+=(--quantize)

  gum spin --title "Generating speech…" -- "${command[@]}"
}

_speak_read_text() {
  if [[ ! -t 0 ]]; then
    cat
  else
    gum write --placeholder "Text to speak"
  fi
}

_speak_play() {
  local text="$1" tmpdir output_path exit_code

  if [[ -z "${text//[[:space:]]/}" ]]; then
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
    printf 'Language\t%s\n' "${speak_config[language]}"
    printf 'Custom config\t%s\n' "${speak_config[config]:-default}"
    printf 'Device\t%s\n' "${speak_config[device]}"
    printf 'Quantize\t%s\n' "${speak_config[quantize]}"
    printf 'LSD decode steps\t%s\n' "${speak_config[lsd_decode_steps]:-Pocket default}"
    printf 'Temperature\t%s\n' "${speak_config[temperature]:-Pocket default}"
    printf 'Noise clamp\t%s\n' "${speak_config[noise_clamp]:-Pocket default}"
    printf 'EOS threshold\t%s\n' "${speak_config[eos_threshold]:-Pocket default}"
    printf 'Frames after EOS\t%s\n' "${speak_config[frames_after_eos]:-Pocket default}"
    printf 'Max tokens\t%s\n' "${speak_config[max_tokens]:-Pocket default}"
    printf 'Server host\t%s\n' "${speak_config[server_host]}"
    printf 'Server port\t%s\n' "${speak_config[server_port]}"
    printf 'Server reload\t%s\n' "${speak_config[server_reload]}"
  } | gum table --print --separator=$'\t'
}

_speak_set_value() {
  local key="$1" header="$2" value

  value="$(gum input --header "$header" --value "${speak_config[$key]}")" || return
  speak_config[$key]="$value"
  _speak_save_settings
}

_speak_choose_voice() {
  local voice

  voice="$(gum choose --header "Pocket TTS voice" \
    alba anna azelma bill_boerst caro_davy charles cosette eponine eve fantine \
    george jane jean javert marius mary michael paul peter_yearsley stuart_bell \
    vera giovanni lola juergen rafael estelle 'Custom path or URL…')" || return

  if [[ "$voice" == 'Custom path or URL…' ]]; then
    voice="$(gum input --header "WAV/MP3/safetensors path or hf:// URL")" || return
  fi
  [[ -n "$voice" ]] || return 64

  speak_config[voice]="$voice"
  _speak_save_settings
}

_speak_model_settings() {
  local choice language

  while true; do
    choice="$(gum choose --header "Model settings" \
      'Language' 'Custom model config' 'Device' 'Quantization' 'Back')" || return
    case "$choice" in
      Language)
        language="$(gum choose --header "Pocket TTS language" \
          english english_2026-01 english_2026-04 french_24l german german_24l \
          italian italian_24l portuguese portuguese_24l spanish spanish_24l)" || continue
        speak_config[language]="$language"
        speak_config[config]=''
        _speak_save_settings
        ;;
      'Custom model config')
        _speak_set_value config "Local model YAML path (blank restores language model)"
        [[ -n "${speak_config[config]}" ]] || _speak_save_settings
        ;;
      Device)
        choice="$(gum choose --header "PyTorch device" cpu mps cuda 'Custom…')" || continue
        if [[ "$choice" == 'Custom…' ]]; then
          _speak_set_value device "PyTorch device"
        else
          speak_config[device]="$choice"
          _speak_save_settings
        fi
        ;;
      Quantization)
        choice="$(gum choose --header "Use CPU int8 quantization?" false true)" || continue
        speak_config[quantize]="$choice"
        _speak_save_settings
        ;;
      Back) return ;;
    esac
  done
}

_speak_generation_settings() {
  local choice

  while true; do
    choice="$(gum choose --header "Generation settings" \
      'LSD decode steps' 'Temperature' 'Noise clamp' 'EOS threshold' \
      'Frames after EOS' 'Max tokens' 'Reset generation defaults' 'Back')" || return
    case "$choice" in
      'LSD decode steps') _speak_set_value lsd_decode_steps "Generation steps (blank uses Pocket default)" ;;
      Temperature) _speak_set_value temperature "Temperature (blank uses Pocket default)" ;;
      'Noise clamp') _speak_set_value noise_clamp "Noise clamp (blank uses Pocket default)" ;;
      'EOS threshold') _speak_set_value eos_threshold "EOS threshold (blank uses Pocket default)" ;;
      'Frames after EOS') _speak_set_value frames_after_eos "Frames generated after EOS (blank uses Pocket default)" ;;
      'Max tokens') _speak_set_value max_tokens "Maximum tokens per chunk (blank uses Pocket default)" ;;
      'Reset generation defaults')
        _speak_reset_generation_settings
        _speak_save_settings
        ;;
      Back) return ;;
    esac
  done
}

_speak_server_settings() {
  local choice

  while true; do
    choice="$(gum choose --header "Server settings" Host Port Reload Back)" || return
    case "$choice" in
      Host) _speak_set_value server_host "Server host" ;;
      Port) _speak_set_value server_port "Server port" ;;
      Reload)
        choice="$(gum choose --header "Enable auto-reload?" false true)" || continue
        speak_config[server_reload]="$choice"
        _speak_save_settings
        ;;
      Back) return ;;
    esac
  done
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
      Voice Model Generation Server 'Reset all settings' Done)" || return
    case "$choice" in
      Voice) _speak_choose_voice ;;
      Model) _speak_model_settings ;;
      Generation) _speak_generation_settings ;;
      Server) _speak_server_settings ;;
      'Reset all settings') _speak_defaults; _speak_save_settings ;;
      Done) return ;;
    esac
  done
}

_speak_generate_interactive() {
  local text="$1" destination output_path

  if [[ -z "$text" ]]; then
    text="$(_speak_read_text)" || return
  fi
  [[ -n "${text//[[:space:]]/}" ]] || return 64

  destination="$(gum choose --header "Generated audio" 'Play now' 'Save WAV…')" || return
  if [[ "$destination" == 'Play now' ]]; then
    _speak_play "$text"
    return
  fi

  output_path="$(gum input --header "WAV output path" --value "$PWD/tts_output.wav")" || return
  [[ -n "$output_path" ]] || return 64
  _speak_generate "$text" "$output_path"
}

_speak_serve() {
  local -a command model_args

  _speak_model_args
  model_args=("${reply[@]}")
  command=(
    uvx pocket-tts serve
    --host "${speak_config[server_host]}"
    --port "${speak_config[server_port]}"
    "${model_args[@]}"
  )
  [[ "${speak_config[server_reload]}" == true ]] && command+=(--reload)
  [[ "${speak_config[quantize]}" == true ]] && command+=(--quantize)

  gum style --foreground 212 "Pocket TTS web interface: http://${speak_config[server_host]}:${speak_config[server_port]}"
  "${command[@]}"
}

_speak_export_voice() {
  local audio_path="$1" export_path="$2"
  local -a command model_args

  if [[ -z "$audio_path" ]]; then
    audio_path="$(gum file --file --directory)" || return
  fi
  [[ -n "$audio_path" ]] || return 64

  if [[ -z "$export_path" ]]; then
    export_path="$(gum input --header "safetensors output path" --value "${audio_path%.*}.safetensors")" || return
  fi
  [[ -n "$export_path" ]] || return 64

  _speak_model_args
  model_args=("${reply[@]}")
  command=(uvx pocket-tts export-voice "$audio_path" "$export_path" "${model_args[@]}")
  gum spin --title "Exporting voice embedding…" -- "${command[@]}"
}

_speak_help() {
  cat <<'EOF'
Usage:
  speak "text"             Generate and play speech.
  command | speak           Generate and play piped text.
  speak < file              Generate and play a text file.
  speak settings            Configure Pocket TTS with Gum.
  speak settings show       Print active settings.
  speak settings reset      Restore wrapper defaults.
  speak generate [text]     Choose to play or save a WAV.
  speak serve               Start Pocket TTS's local web interface.
  speak export-voice [input [output]]
                            Convert a voice sample to safetensors.
  speak -- "settings"       Speak text that is also a command name.

All Pocket CLI surfaces are available through generate, serve, export-voice,
and settings. uvx remains the isolated runner; invoke speak, not uvx.
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
    serve|server)
      shift
      (( $# == 0 )) || { print -u2 'usage: speak serve'; return 64; }
      _speak_serve
      ;;
    export-voice|export)
      shift
      (( $# <= 2 )) || { print -u2 'usage: speak export-voice [input [output]]'; return 64; }
      _speak_export_voice "${1:-}" "${2:-}"
      ;;
    generate)
      shift
      _speak_generate_interactive "$*"
      ;;
    help|-h|--help)
      _speak_help
      ;;
    --)
      shift
      _speak_play "$*"
      ;;
    '')
      text="$(_speak_read_text)" || return
      _speak_play "$text"
      ;;
    *)
      _speak_play "$*"
      ;;
  esac
}
