#!/bin/sh
set -eu

DARWIN_REBUILD_REF="github:nix-darwin/nix-darwin/nix-darwin-25.11#darwin-rebuild"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

BOOTSTRAP_USERNAME=""
BOOTSTRAP_HOME=""
BOOTSTRAP_CONFIG_NAME=""
SKIP_INSTALL=0
SKIP_BREW=0
SKIP_LOCK=0
SKIP_REBUILD=0
SKIP_HERDR=0
SKIP_PERMISSIONS=0

usage() {
  cat <<'EOF'
Usage: ./install [options]

Options:
  --user <name>         Override the target macOS user.
  --home <path>         Override the target home directory.
  --config-name <name>  Override the flake configuration name.
  --skip-install        Skip Determinate Nix installation.
  --skip-brew           Skip Homebrew installation and tap trust.
  --skip-lock           Skip creating or refreshing flake.lock.
  --skip-rebuild        Skip the initial darwin-rebuild switch.
  --skip-herdr          Skip the herdr binary install.
  --skip-permissions    Skip the interactive permissions walkthrough.
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

install_herdr() {
  if [ "$SKIP_HERDR" -eq 1 ]; then
    log "Skipping herdr install."
    return 0
  fi

  if command -v herdr >/dev/null 2>&1; then
    log "herdr already present; skipping installer."
    return 0
  fi

  if [ -x "$HOME_DIR/.local/bin/herdr" ]; then
    log "herdr already present at ~/.local/bin/herdr; skipping installer."
    return 0
  fi

  need_cmd curl

  # herdr ships a prebuilt binary that drops into ~/.local/bin/herdr
  # (already on PATH via home.sessionPath in modules/home-manager/shell.nix).
  # Config lives in ~/.config/herdr/config.toml and is owned by
  # modules/home-manager/herdr.nix.
  log "Installing herdr."
  curl -fsSL https://herdr.dev/install.sh | sh
}

brew_bin() {
  if [ -x /opt/homebrew/bin/brew ]; then
    printf '/opt/homebrew/bin/brew'
  elif [ -x /usr/local/bin/brew ]; then
    printf '/usr/local/bin/brew'
  else
    return 1
  fi
}

# nix-darwin's homebrew module configures Homebrew but does NOT install it;
# without this step the first darwin-rebuild aborts at `brew bundle`.
install_homebrew() {
  if [ "$SKIP_BREW" -eq 1 ]; then
    log "Skipping Homebrew installation."
    return 0
  fi

  if brew_bin >/dev/null; then
    log "Homebrew already present; skipping installer."
  else
    need_cmd curl
    log "Installing Homebrew (also installs Xcode Command Line Tools if missing)."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  trust_taps
}

# Homebrew's HOMEBREW_REQUIRE_TAP_TRUST refuses untrusted third-party taps,
# which aborts the first `brew bundle` mid-activation. Trust is per-user
# mutable state (~/.homebrew/trust.json), so it must be granted here before
# the rebuild. Taps are read from modules/darwin/homebrew.nix to keep a
# single source of truth; official homebrew/* taps need no trust.
trust_taps() {
  brew=$(brew_bin) || return 0

  if ! "$brew" trust --help >/dev/null 2>&1; then
    log "brew trust not supported by this Homebrew; skipping tap trust."
    return 0
  fi

  sed -n '/taps = \[/,/\];/p' "$REPO_ROOT/modules/darwin/homebrew.nix" \
    | sed -n 's/^[[:space:]]*"\(.*\)".*/\1/p' \
    | while IFS= read -r tap; do
        case "$tap" in
          homebrew/*) ;;
          *)
            log "Trusting tap $tap."
            "$brew" trust --tap "$tap" || log "WARN: failed to trust tap $tap"
            ;;
        esac
      done
}

# Mac App Store apps (homebrew.masApps) install via mas during the first
# rebuild, and mas requires an App Store sign-in that cannot be automated.
prompt_app_store_signin() {
  [ "$SKIP_REBUILD" -eq 0 ] || return 0
  [ -t 0 ] || return 0

  printf 'Mac App Store apps install during the rebuild and need an App Store sign-in.\n' >&2
  printf 'Press Enter to open the App Store and sign in, or type s to skip: ' >&2
  read -r answer || answer=s
  if [ "$answer" != "s" ] && [ "$answer" != "S" ]; then
    open -a "App Store" >/dev/null 2>&1 || true
    printf 'Press Enter once signed in (or to continue anyway): ' >&2
    read -r _ || true
  fi
}

# Per ADR 16: Home Manager's backupFileExtension does not catch symlinks at
# managed target paths, and a leftover ~/dotfiles symlink aborts the whole
# user activation. Remove only symlinks that resolve into ~/dotfiles; the
# dotfiles targets themselves are preserved (D17).
preclear_dotfile_symlinks() {
  for rel in .zshrc .zprofile .gitconfig .config/ghostty/config; do
    p="$HOME_DIR/$rel"
    [ -L "$p" ] || continue
    case "$(readlink "$p")" in
      "$HOME_DIR/dotfiles"/*|*/dotfiles/*)
        log "Removing legacy dotfiles symlink $p (target preserved)."
        rm -f "$p"
        ;;
    esac
  done
}

# The Determinate installer writes /etc/nix/nix.custom.conf; the Determinate
# darwin module manages that same file, and nix-darwin aborts the FIRST
# activation if the installer's content hash is not one it recognizes
# (installer newer than the pinned module input). Moving it aside is the
# upstream-prescribed remedy; the module writes its managed version
# immediately after. Only runs before the first-ever nix-darwin activation.
preclear_etc_for_first_activation() {
  [ -e /run/current-system ] && return 0

  f=/etc/nix/nix.custom.conf
  if [ -e "$f" ] && [ ! -e "$f.before-nix-darwin" ]; then
    log "Moving installer-owned $f aside for first activation."
    sudo mv "$f" "$f.before-nix-darwin"
  fi
}

run_permissions_walkthrough() {
  if [ "$SKIP_PERMISSIONS" -eq 1 ]; then
    log "Skipping permissions walkthrough."
    return 0
  fi

  if [ ! -t 0 ]; then
    log "Non-interactive session; run scripts/permissions-walkthrough.sh later."
    return 0
  fi

  bash "$REPO_ROOT/scripts/permissions-walkthrough.sh" || true
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

# A git+file flake only evaluates TRACKED files: a freshly generated host file
# that is not `git add`ed is invisible, and the rebuild fails with
# "does not provide attribute darwinConfigurations.<name>.system".
track_host_file() {
  command -v git >/dev/null 2>&1 || return 0
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  git -C "$REPO_ROOT" add "$HOST_DIR" || log "WARN: could not git-add $HOST_DIR"
}

# Offer to name the machine before anything derives from LocalHostName
# (flake config name, generated host file, scutil-sourced metadata). The
# host file then keeps enforcing the name declaratively on every switch.
prompt_machine_rename() {
  [ -t 0 ] || return 0
  [ -z "$BOOTSTRAP_CONFIG_NAME" ] || return 0

  current=$(read_scutil LocalHostName)
  [ -n "$current" ] || current=$(hostname -s)

  printf 'Machine name (becomes LocalHostName/HostName/ComputerName and the flake config) [%s]: ' "$current" >&2
  read -r new_name || new_name=""
  [ -n "$new_name" ] || return 0
  [ "$new_name" != "$current" ] || return 0

  case "$new_name" in
    *[!A-Za-z0-9-]*)
      fail "machine name must contain only letters, digits, and hyphens: $new_name"
      ;;
  esac

  need_cmd sudo
  log "Renaming machine to $new_name (requires sudo)."
  sudo scutil --set LocalHostName "$new_name"
  sudo scutil --set HostName "$new_name"
  sudo scutil --set ComputerName "$new_name"
}

# git needs the Xcode Command Line Tools; a bare machine that got this repo
# without cloning (e.g. tarball) may not have them yet.
ensure_clt() {
  if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools missing; triggering installer."
    /usr/bin/xcode-select --install >/dev/null 2>&1 || true
    fail "confirm the Command Line Tools dialog, wait for it to finish, then re-run ./install"
  fi
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
    --skip-brew)
      SKIP_BREW=1
      shift
      ;;
    --skip-permissions)
      SKIP_PERMISSIONS=1
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
    --skip-herdr)
      SKIP_HERDR=1
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

ensure_clt
prompt_machine_rename

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
track_host_file

if [ "$SKIP_INSTALL" -eq 0 ] || [ "$SKIP_LOCK" -eq 0 ] || [ "$SKIP_REBUILD" -eq 0 ]; then
  install_determinate_nix
fi

install_homebrew
prompt_app_store_signin
preclear_dotfile_symlinks

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

  preclear_etc_for_first_activation

  log "Running darwin-rebuild for $CONFIG_NAME."
  # -H gives root its own $HOME; without it nix warns "$HOME ... is not owned
  # by you" and falls back to /var/root anyway.
  sudo -H "$NIX_BIN" run "$DARWIN_REBUILD_REF" -- switch --flake "$REPO_ROOT#$CONFIG_NAME"
else
  log "Skipping darwin-rebuild."
fi

install_herdr
run_permissions_walkthrough
