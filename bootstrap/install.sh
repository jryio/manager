#!/bin/sh
set -eu

DARWIN_REBUILD_REF="github:nix-darwin/nix-darwin/nix-darwin-25.11#darwin-rebuild"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

BOOTSTRAP_USERNAME=""
BOOTSTRAP_HOME=""
BOOTSTRAP_CONFIG_NAME=""
SKIP_INSTALL=0
SKIP_LOCK=0
SKIP_REBUILD=0

usage() {
  cat <<'EOF'
Usage: ./install [options]

Options:
  --user <name>         Override the target macOS user.
  --home <path>         Override the target home directory.
  --config-name <name>  Override the flake configuration name.
  --skip-install        Skip Determinate Nix installation.
  --skip-lock           Skip creating or refreshing flake.lock.
  --skip-rebuild        Skip the initial darwin-rebuild switch.
  -h, --help            Show this help text.
EOF
}

log() {
  printf '%s\n' "$*" >&2
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

escape_nix_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

read_scutil() {
  scutil --get "$1" 2>/dev/null || true
}

run_nix() {
  nix \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    "$@"
}

load_nix() {
  if command -v nix >/dev/null 2>&1; then
    return 0
  fi

  for candidate in \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    /nix/var/nix/profiles/default/etc/profile.d/nix.sh \
    "$HOME/.nix-profile/etc/profile.d/nix.sh"
  do
    if [ -f "$candidate" ]; then
      # shellcheck disable=SC1090
      . "$candidate"
      break
    fi
  done

  command -v nix >/dev/null 2>&1 || fail "nix is installed but not available on PATH"
}

install_determinate_nix() {
  if [ "$SKIP_INSTALL" -eq 1 ]; then
    log "Skipping Determinate Nix installation."
    return 0
  fi

  if command -v nix >/dev/null 2>&1; then
    log "nix already present; skipping installer."
    return 0
  fi

  need_cmd curl

  log "Installing Determinate Nix."
  curl --fail --location --proto '=https' --tlsv1.2 https://install.determinate.systems/nix \
    | sh -s -- install macos --determinate --no-confirm
}

write_host_file() {
  host_dir=$1
  host_file=$2
  config_name=$3
  host_name=$4
  local_host_name=$5
  computer_name=$6
  system_name=$7
  username=$8
  home_dir=$9
  full_name=${10}

  mkdir -p "$host_dir"

  cat >"$host_file" <<EOF
{
  system = "$(escape_nix_string "$system_name")";
  username = "$(escape_nix_string "$username")";
  homeDirectory = "$(escape_nix_string "$home_dir")";
  fullName = "$(escape_nix_string "$full_name")";

  hostName = "$(escape_nix_string "$host_name")";
  localHostName = "$(escape_nix_string "$local_host_name")";
  computerName = "$(escape_nix_string "$computer_name")";

  stateVersion = 6;
  homeStateVersion = "25.11";
}
EOF

  log "Created $host_file for configuration $config_name."
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)
      [ "$#" -ge 2 ] || fail "--user requires a value"
      BOOTSTRAP_USERNAME=$2
      shift 2
      ;;
    --home)
      [ "$#" -ge 2 ] || fail "--home requires a value"
      BOOTSTRAP_HOME=$2
      shift 2
      ;;
    --config-name)
      [ "$#" -ge 2 ] || fail "--config-name requires a value"
      BOOTSTRAP_CONFIG_NAME=$2
      shift 2
      ;;
    --skip-install)
      SKIP_INSTALL=1
      shift
      ;;
    --skip-lock)
      SKIP_LOCK=1
      shift
      ;;
    --skip-rebuild)
      SKIP_REBUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || fail "this bootstrap only supports macOS"
[ "$(id -u)" -ne 0 ] || fail "run this bootstrap as the target macOS user, not as root"

need_cmd hostname
need_cmd id
need_cmd sed

case "$(uname -m)" in
  arm64)
    SYSTEM_NAME="aarch64-darwin"
    ;;
  x86_64)
    SYSTEM_NAME="x86_64-darwin"
    ;;
  *)
    fail "unsupported macOS architecture: $(uname -m)"
    ;;
esac

USERNAME=${BOOTSTRAP_USERNAME:-$(id -un)}
HOME_DIR=${BOOTSTRAP_HOME:-$HOME}
HOST_NAME=$(read_scutil HostName)
LOCAL_HOST_NAME=$(read_scutil LocalHostName)
COMPUTER_NAME=$(read_scutil ComputerName)
FULL_NAME=$(id -F 2>/dev/null || printf '%s' "$USERNAME")

[ -n "$LOCAL_HOST_NAME" ] || LOCAL_HOST_NAME=$(hostname -s)
[ -n "$HOST_NAME" ] || HOST_NAME=$LOCAL_HOST_NAME
[ -n "$COMPUTER_NAME" ] || COMPUTER_NAME=$LOCAL_HOST_NAME

CONFIG_NAME=${BOOTSTRAP_CONFIG_NAME:-$LOCAL_HOST_NAME}
HOST_DIR="$REPO_ROOT/hosts/$CONFIG_NAME"
HOST_FILE="$HOST_DIR/default.nix"

if [ ! -f "$HOST_FILE" ]; then
  write_host_file \
    "$HOST_DIR" \
    "$HOST_FILE" \
    "$CONFIG_NAME" \
    "$HOST_NAME" \
    "$LOCAL_HOST_NAME" \
    "$COMPUTER_NAME" \
    "$SYSTEM_NAME" \
    "$USERNAME" \
    "$HOME_DIR" \
    "$FULL_NAME"
else
  log "Using existing host definition at $HOST_FILE."
fi

if [ "$SKIP_INSTALL" -eq 0 ] || [ "$SKIP_LOCK" -eq 0 ] || [ "$SKIP_REBUILD" -eq 0 ]; then
  install_determinate_nix
fi

if [ "$SKIP_LOCK" -eq 0 ] || [ "$SKIP_REBUILD" -eq 0 ]; then
  load_nix
fi

if [ "$SKIP_LOCK" -eq 0 ]; then
  if [ ! -f "$REPO_ROOT/flake.lock" ]; then
    log "Creating flake.lock."
    (
      cd "$REPO_ROOT"
      run_nix flake lock
    )
  else
    log "flake.lock already present; leaving it unchanged."
  fi
else
  log "Skipping flake.lock creation."
fi

if [ "$SKIP_REBUILD" -eq 0 ]; then
  need_cmd sudo
  NIX_BIN=$(command -v nix)

  log "Running darwin-rebuild for $CONFIG_NAME."
  sudo "$NIX_BIN" run "$DARWIN_REBUILD_REF" -- switch --flake "$REPO_ROOT#$CONFIG_NAME"
else
  log "Skipping darwin-rebuild."
fi
