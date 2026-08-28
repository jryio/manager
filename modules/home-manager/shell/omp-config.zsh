# Import deliberate OMP configuration changes into the manager checkout.
#
# omp-config-import [--yes] [repo-path]
# Show the pending diff, then copy ~/.omp/agent/config.yml into the repo.
omp-config-import() {
  emulate -L zsh
  local assume_yes=0 repo source live diff_status reply

  if [[ $1 == --yes ]]; then
    assume_yes=1
    shift
  fi
  if [[ -n $1 && -d $1 ]]; then
    repo=${1:A}
    shift
  fi
  if (( $# )); then
    print -u2 'usage: omp-config-import [--yes] [repo-path]'
    return 2
  fi

  repo=${repo:-$(_manager_repo_root)}
  source="$repo/modules/home-manager/assets/omp/config.yml"
  live="$HOME/.omp/agent/config.yml"
  if [[ ! -f $source ]]; then
    print -u2 "omp-config-import: no managed config at $source"
    return 1
  fi
  if [[ ! -f $live ]]; then
    print -u2 "omp-config-import: no live config at $live"
    return 1
  fi

  git diff --no-index -- "$source" "$live"
  diff_status=$?
  case $diff_status in
    0)
      print 'omp-config-import: live config already matches the repo'
      return 0
      ;;
    1)
      ;;
    *)
      return $diff_status
      ;;
  esac

  if (( ! assume_yes )); then
    print -n 'Import this live configuration? [y/N] '
    read -r reply
    if [[ $reply != [yY] ]]; then
      print 'omp-config-import: unchanged'
      return 1
    fi
  fi

  /bin/cp "$live" "$source"
  print "omp-config-import: updated $source"
}
