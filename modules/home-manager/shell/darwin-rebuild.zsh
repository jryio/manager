# darwin-rebuild wrappers.
#
# These deliberately resolve the repo path and host name at RUN time rather
# than baking them in at build time. The previous `drs` alias froze both into
# ~/.zshrc, which meant a stale generation could point at another machine's
# home directory and config name -- and you could not use the alias to fix
# itself, because fixing it required running it. Nothing here depends on the
# generation it shipped in.
#
# Repo resolution: explicit argument > enclosing manager checkout > ~/manager.
# The enclosing checkout wins so that running `drs` inside a worktree rebuilds
# THAT worktree. The resolved target is always printed before sudo runs.
#
# Host resolution: LocalHostName, matching how bootstrap/install.sh derives
# CONFIG_NAME. Renaming the machine therefore takes effect immediately.

# Print the manager checkout that should be rebuilt.
_manager_repo_root() {
  emulate -L zsh
  local toplevel
  if toplevel=$(git rev-parse --show-toplevel 2>/dev/null); then
    # Both markers, so an unrelated flake repo can never be mistaken for this one.
    if [[ -f $toplevel/flake.nix && -d $toplevel/hosts ]]; then
      print -r -- "$toplevel"
      return 0
    fi
  fi
  print -r -- "$HOME/manager"
}

# Resolve repo + host and echo them as "<repo>\n<host>", or fail with a reason.
_manager_flake_target() {
  emulate -L zsh
  local repo=$1 host

  if [[ -z $repo ]]; then
    repo=$(_manager_repo_root)
  fi

  if [[ ! -f $repo/flake.nix ]]; then
    print -u2 "manager: no flake.nix under $repo"
    return 1
  fi

  host=$(scutil --get LocalHostName 2>/dev/null)
  if [[ -z $host ]]; then
    print -u2 "manager: could not read LocalHostName from scutil"
    return 1
  fi

  if [[ ! -f $repo/hosts/$host/default.nix ]]; then
    print -u2 "manager: no host config for '$host' in $repo/hosts"
    print -u2 "manager: available: ${(j:, :)$(cd $repo/hosts && print -l *(/N))}"
    return 1
  fi

  print -r -- "$repo"
  print -r -- "$host"
}

# drs [repo-path] [extra darwin-rebuild args...]
# Switch this machine to its own host config.
drs() {
  emulate -L zsh
  local repo="" target

  if [[ -n $1 && -d $1 ]]; then
    repo=${1:A}
    shift
  fi

  target=$(_manager_flake_target "$repo") || return 1
  local root=${target%%$'\n'*} host=${target##*$'\n'}

  print -u2 -r -- "drs: switching $root#$host"
  # path: (not the bare path) so uncommitted work is included -- a git+file
  # flake would silently evaluate only tracked files.
  sudo darwin-rebuild switch --flake "path:$root#$host" "$@"
}

# drb [repo-path] [extra nix build args...]
# Build the system closure without sudo or activation. This is the cheap
# pre-flight check before drs.
drb() {
  emulate -L zsh
  local repo="" target

  if [[ -n $1 && -d $1 ]]; then
    repo=${1:A}
    shift
  fi

  target=$(_manager_flake_target "$repo") || return 1
  local root=${target%%$'\n'*} host=${target##*$'\n'}

  print -u2 -r -- "drb: building $root#$host"
  nix build "path:$root#darwinConfigurations.$host.system" --no-link "$@"
}
