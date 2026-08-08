# hwt <name> — create a herdr worktree from the current repo, then apply a
# per-repo pane layout. hlo — reset the current tab to that same layout.
# Add repos as new case arms in _hwt_layout_fn + _hwt_layout_* helpers.
hwt() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "usage: hwt <worktree-name>" >&2
    return 1
  fi

  local repo_root branch resp pane_id tab_id checkout layout

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

  herdr tab rename "$tab_id" "$name" > /dev/null

  layout="$(_hwt_layout_fn "$repo_root")"
  [[ -n "$layout" ]] && "$layout" "$pane_id" "$checkout"
}

# hlo — re-layout the current tab: close every other pane in it (killing
# whatever they are running), then rebuild the hwt layout around this pane.
hlo() {
  local resp pane_id tab_id cwd main_root checkout layout other

  resp="$(herdr pane current)" || return 1
  pane_id="$(echo "$resp" | jq -r '.result.pane.pane_id // empty')"
  tab_id="$(echo "$resp" | jq -r '.result.pane.tab_id // empty')"
  cwd="$(echo "$resp" | jq -r '.result.pane.cwd // empty')"

  if [[ -z "$pane_id" || -z "$tab_id" || -z "$cwd" ]]; then
    echo "hlo: unexpected response from herdr pane current:" >&2
    echo "$resp" >&2
    return 1
  fi

  checkout="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || {
    echo "hlo: $cwd is not inside a git repository" >&2
    return 1
  }

  # Dispatch on the main repo root so herdr worktree checkouts match too.
  main_root="$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir)"
  main_root="${main_root%/.git}"

  layout="$(_hwt_layout_fn "$main_root")"
  if [[ -z "$layout" ]]; then
    echo "hlo: no layout defined for $main_root" >&2
    return 1
  fi

  herdr pane list \
    | jq -r --arg tab "$tab_id" --arg self "$pane_id" \
        '.result.panes[] | select(.tab_id == $tab and .pane_id != $self) | .pane_id' \
    | while IFS= read -r other; do
        herdr pane close "$other" > /dev/null
      done

  "$layout" "$pane_id" "$checkout"
}

_hwt_layout_fn() {
  case "$1" in
    */cloudx/cloudx) echo _hwt_layout_cloudx ;;
  esac
}

_hwt_split() {
  herdr pane split "$1" --direction "$2" --ratio 0.5 --cwd "$3" --no-focus \
    | jq -r '.result.pane.pane_id'
}

# Left half: main shell (keeps focus throughout). Right half: four stacked
# quarter panes — typescript, provisioning, admin, and a spare shell.
_hwt_layout_cloudx() {
  local pane_main="$1" checkout="$2"
  local pane_ts pane_admin pane_prov

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
