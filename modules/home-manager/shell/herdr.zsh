# hwt <name> — create a herdr worktree from the current repo, then apply a
# per-repo pane layout. Add repos as new case arms + _hwt_layout_* helpers.
hwt() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "usage: hwt <worktree-name>" >&2
    return 1
  fi

  local repo_root branch resp pane_id tab_id checkout

  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "hwt: not inside a git repository" >&2
    return 1
  }

  branch="$name"
  [[ "$branch" != */* ]] && branch="jryio/$branch"

  resp="$(herdr worktree create --cwd "$repo_root" --branch "$branch" --focus --json)" || return 1
  pane_id="$(echo "$resp" | jq -r '.result.root_pane.pane_id // empty')"
  tab_id="$(echo "$resp" | jq -r '.result.root_pane.tab_id // empty')"
  checkout="$(echo "$resp" | jq -r '.result.worktree.path // empty')"

  if [[ -z "$pane_id" || -z "$tab_id" || -z "$checkout" ]]; then
    echo "hwt: unexpected response from herdr worktree create:" >&2
    echo "$resp" >&2
    return 1
  fi

  case "$repo_root" in
    */cloudx/cloudx) _hwt_layout_cloudx "$pane_id" "$tab_id" "$checkout" "$name" ;;
  esac
}

_hwt_split() {
  herdr pane split "$1" --direction "$2" --ratio 0.5 --cwd "$3" --no-focus \
    | jq -r '.result.pane.pane_id'
}

# Left half: main shell (keeps focus throughout). Right half: four stacked
# quarter panes — typescript, provisioning, admin, and a spare shell.
_hwt_layout_cloudx() {
  local pane_main="$1" tab_id="$2" checkout="$3" name="$4"
  local pane_ts pane_admin pane_prov

  herdr tab rename "$tab_id" "$name" > /dev/null

  pane_ts="$(_hwt_split "$pane_main" right "$checkout")"
  pane_admin="$(_hwt_split "$pane_ts" down "$checkout")"
  pane_prov="$(_hwt_split "$pane_ts" down "$checkout")"
  _hwt_split "$pane_admin" down "$checkout" > /dev/null

  herdr pane rename "$pane_ts" typescript > /dev/null
  herdr pane rename "$pane_prov" provisioning > /dev/null
  herdr pane rename "$pane_admin" admin > /dev/null

  herdr pane run "$pane_ts" 'docker compose up -d && mise run -C typescript //:typescript:install && mise run -C typescript //:typescript:dev'
  herdr pane run "$pane_prov" 'mise run //:provisioning:air'
  herdr pane run "$pane_admin" 'mise run //:admin-service:air'
}
