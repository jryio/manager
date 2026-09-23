# Interactively delete local branches absent from origin whose GitHub PR has
# closed or whose origin upstream vanished. Safe deletion leaves unmerged work.
prune-branches() {
  setopt localoptions no_aliases pipefail

  local repository owner name closed_prs query mode selected branch number state head_oid branch_head_key
  local ref remote_branch upstream_remote tracking
  local -a local_branches remote_refs candidates selected_branches reasons delete_args
  local -A checked_out remote_exists pr_reason merged_pr local_oid upstream_gone force_delete
  local failures=0

  if ! command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 'prune-branches: run this inside a Git repository'
    return 2
  fi

  if (( ! $+commands[gh] )); then
    print -u2 'prune-branches: gh is required'
    return 127
  fi

  if (( ! $+commands[gum] )); then
    print -u2 'prune-branches: gum is required'
    return 127
  fi

  print -r -- 'Refreshing origin remote-tracking branches…'
  if ! command git fetch --prune origin; then
    print -u2 'prune-branches: could not refresh origin remote-tracking branches'
    return 1
  fi

  if ! repository="$(command gh repo view --json nameWithOwner --jq .nameWithOwner)"; then
    print -u2 'prune-branches: could not identify this GitHub repository'
    return 1
  fi
  owner=${repository%%/*}
  name=${repository#*/}

  query='query($owner: String!, $name: String!, $endCursor: String) {
    repository(owner: $owner, name: $name) {
      pullRequests(first: 100, states: [CLOSED, MERGED], after: $endCursor) {
      nodes { number headRefName headRefOid mergedAt }
        pageInfo { hasNextPage endCursor }
      }
    }
  }'
  if ! closed_prs="$(command gh api graphql --paginate \
    -f owner="$owner" \
    -f name="$name" \
    -f query="$query" \
    --jq '.data.repository.pullRequests.nodes[] | [.headRefName, (.number | tostring), (if .mergedAt then "merged" else "closed" end), (.headRefOid // "")] | @tsv')"; then
    print -u2 'prune-branches: could not retrieve closed GitHub pull requests'
    return 1
  fi

  while IFS=$'\t' read -r branch number state head_oid; do
    [[ -n "$branch" && -z "${pr_reason[$branch]-}" ]] || continue
    pr_reason[$branch]="PR #$number $state"
    if [[ "$state" == merged && -n "$head_oid" ]]; then
      branch_head_key="$branch:$head_oid"
      merged_pr[$branch_head_key]="PR #$number merged"
    fi
  done <<< "$closed_prs"

  while IFS= read -r ref; do
    [[ "$ref" == branch\ refs/heads/* ]] || continue
    checked_out[${ref#branch refs/heads/}]=1
  done < <(command git worktree list --porcelain)

  remote_refs=("${(@f)$(command git for-each-ref --format='%(refname)' refs/remotes/origin)}")
  for ref in "${remote_refs[@]}"; do
    remote_branch=${ref#refs/remotes/origin/}
    [[ "$remote_branch" != "$ref" && "$remote_branch" != HEAD ]] || continue
    remote_exists[$remote_branch]=1
  done

  while IFS=$'\t' read -r branch upstream_remote tracking; do
    [[ "$upstream_remote" == origin && "$tracking" == *'[gone]'* ]] && upstream_gone[$branch]=1
  done < <(LC_ALL=C command git for-each-ref --format='%(refname:short)%09%(upstream:remotename)%09%(upstream:track)' refs/heads)

  while IFS=$'\t' read -r branch head_oid; do
    [[ -n "$branch" ]] || continue
    local_branches+=("$branch")
    local_oid[$branch]=$head_oid
  done < <(command git for-each-ref --format='%(refname:short)%09%(objectname)' refs/heads)
  for branch in "${local_branches[@]}"; do
    [[ -z "${checked_out[$branch]-}" && -z "${remote_exists[$branch]-}" ]] || continue

    branch_head_key="$branch:${local_oid[$branch]}"
    if [[ -n "${merged_pr[$branch_head_key]-}" ]]; then
      pr_reason[$branch]="${merged_pr[$branch_head_key]}"
      force_delete[$branch]=1
    fi

    reasons=()
    [[ -n "${pr_reason[$branch]-}" ]] && reasons+=("${pr_reason[$branch]}")
    [[ -n "${upstream_gone[$branch]-}" ]] && reasons+=('upstream gone')
    (( ${#reasons[@]} > 0 )) || continue

    candidates+=("$branch"$'\t'"${(j:; :)reasons}")
  done

  if (( ${#candidates[@]} == 0 )); then
    gum style --foreground 240 'No stale local branches matched closed PRs or gone upstreams.'
    return 0
  fi

  mode="$(gum choose --header "${#candidates[@]} stale local branches found" \
    'Choose branches' 'Delete all candidates')" || return 0
  case "$mode" in
    'Choose branches')
      selected="$(printf '%s\n' "${candidates[@]}" | gum choose --no-limit \
        --header 'Select branches to delete locally (tab toggles, enter confirms)')" || return 0
      ;;
    'Delete all candidates') selected="$(printf '%s\n' "${candidates[@]}")" ;;
    *) return 0 ;;
  esac

  while IFS= read -r ref; do
    [[ -n "$ref" ]] || continue
    selected_branches+=("${ref%%$'\t'*}")
  done <<< "$selected"

  if (( ${#selected_branches[@]} == 0 )); then
    gum style --foreground 240 'No branches selected.'
    return 0
  fi

  if ! gum confirm "Delete ${#selected_branches[@]} local branch(es)? Exact merged PR tips use --force; others use safe deletion."; then
    return 0
  fi

  for branch in "${selected_branches[@]}"; do
    if [[ -n "${force_delete[$branch]-}" ]]; then
      delete_args=(--delete --force)
    else
      delete_args=(--delete)
    fi
    if ! command git branch "${delete_args[@]}" -- "$branch"; then
      print -u2 "prune-branches: kept $branch (not safely deletable; inspect it, then use git branch -D if intended)"
      failures=1
    fi
  done

  return "$failures"
}
