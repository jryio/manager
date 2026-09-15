# Interactively delete local branches whose remote no longer exists and whose
# upstream vanished or GitHub PR has closed. Safe deletion leaves unmerged work.
prune-branches() {
  setopt localoptions no_aliases pipefail

  local repository owner name closed_prs query mode selected branch number state
  local ref remote_ref remote_branch tracking reason
  local -a local_branches remote_refs candidates selected_branches reasons
  local -A checked_out remote_exists pr_reason upstream_gone
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

  print -r -- 'Refreshing remote-tracking branches…'
  if ! command git fetch --all --prune; then
    print -u2 'prune-branches: could not refresh remote-tracking branches'
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
      pullRequests(first: 100, states: CLOSED, after: $endCursor) {
        nodes { number headRefName mergedAt }
        pageInfo { hasNextPage endCursor }
      }
    }
  }'
  if ! closed_prs="$(command gh api graphql --paginate \
    -f owner="$owner" \
    -f name="$name" \
    -f query="$query" \
    --jq '.data.repository.pullRequests.nodes[] | [.headRefName, (.number | tostring), (if .mergedAt then "merged" else "closed" end)] | @tsv')"; then
    print -u2 'prune-branches: could not retrieve closed GitHub pull requests'
    return 1
  fi

  while IFS=$'\t' read -r branch number state; do
    [[ -n "$branch" && -z "${pr_reason[$branch]-}" ]] || continue
    pr_reason[$branch]="PR #$number $state"
  done <<< "$closed_prs"

  while IFS= read -r ref; do
    [[ "$ref" == branch\ refs/heads/* ]] || continue
    checked_out[${ref#branch refs/heads/}]=1
  done < <(command git worktree list --porcelain)

  remote_refs=("${(@f)$(command git for-each-ref --format='%(refname)' refs/remotes)}")
  for ref in "${remote_refs[@]}"; do
    remote_ref=${ref#refs/remotes/}
    remote_branch=${remote_ref#*/}
    [[ "$remote_ref" != "$remote_branch" && "$remote_branch" != HEAD ]] || continue
    remote_exists[$remote_branch]=1
  done

  while IFS=$'\t' read -r branch tracking; do
    [[ "$tracking" == *'[gone]'* ]] && upstream_gone[$branch]=1
  done < <(LC_ALL=C command git for-each-ref --format='%(refname:short)%09%(upstream:track)' refs/heads)

  local_branches=("${(@f)$(command git for-each-ref --format='%(refname:short)' refs/heads)}")
  for branch in "${local_branches[@]}"; do
    [[ -z "${checked_out[$branch]-}" && -z "${remote_exists[$branch]-}" ]] || continue

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

  if ! gum confirm "Delete ${#selected_branches[@]} local branch(es) with git branch --delete?"; then
    return 0
  fi

  for branch in "${selected_branches[@]}"; do
    if ! command git branch --delete -- "$branch"; then
      print -u2 "prune-branches: kept $branch (not safely deletable; inspect it, then use git branch -D if intended)"
      failures=1
    fi
  done

  return "$failures"
}
