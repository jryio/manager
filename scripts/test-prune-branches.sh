#!/bin/zsh
set -euo pipefail

repo_root=${0:A:h:h}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/prune-branches-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin"

cat > "$tmpdir/bin/git" <<'EOF'
#!/bin/zsh
case "$1" in
  rev-parse)
    [[ "$2" == --is-inside-work-tree ]] && print -r -- true
    ;;
  fetch)
    print -r -- "fetch:$*" >> "$GIT_PRUNE_TEST_LOG"
    if [[ "$*" != 'fetch --prune origin' ]]; then
      print -u2 "unexpected fetch: $*"
      exit 64
    fi
    ;;
  worktree)
    print -r -- 'worktree /tmp/repo'
    print -r -- 'branch refs/heads/main'
    print -r -- 'worktree /tmp/linked'
    print -r -- 'branch refs/heads/worktree'
    ;;
  for-each-ref)
    case "$*" in
      *'%(refname)'*'refs/remotes/origin')
        print -r -- 'refs/remotes/origin/HEAD'
        print -r -- 'refs/remotes/origin/main'
        print -r -- 'refs/remotes/origin/live'
        ;;
      *'%(refname:short)%09%(upstream:remotename)%09%(upstream:track)'*)
        print -r -- $'main\torigin\t[origin/main]'
        print -r -- $'merged\t\t'
        print -r -- $'closed\t\t'
        print -r -- $'gone\torigin\t[gone]'
        print -r -- $'live\torigin\t[origin/live]'
        print -r -- $'worktree\t\t'
        print -r -- $'perf-gone\tperf-node\t[gone]'
        ;;
      *'%(refname:short)%09%(objectname)'*'refs/heads')
        print -r -- $'main\t00000000'
        print -r -- $'merged\taaaaaaaa'
        print -r -- $'closed\tbbbbbbbb'
        print -r -- $'gone\tcccccccc'
        print -r -- $'live\tdddddddd'
        print -r -- $'worktree\teeeeeeee'
        print -r -- $'perf-gone\tffffffff'
        print -r -- $'merged-stale\t99999999'
        ;;
      *)
        print -u2 "unexpected for-each-ref: $*"
        exit 64
        ;;
    esac
    ;;
  branch)
    print -r -- "delete:$*" >> "$GIT_PRUNE_TEST_LOG"
    ;;
  *)
    print -u2 "unexpected git: $*"
    exit 64
    ;;
esac
EOF

cat > "$tmpdir/bin/gh" <<'EOF'
#!/bin/zsh
case "$1" in
  repo)
    print -r -- 'octo/cleanup'
    ;;
  api)
    print -r -- "gh:$*" >> "$GIT_PRUNE_TEST_LOG"
    print -r -- $'closed\t102\tclosed\tbbbbbbbb'
    if [[ "$*" == *'states: [CLOSED, MERGED]'* ]]; then
      print -r -- $'merged\t101\tmerged\taaaaaaaa'
      print -r -- $'worktree\t103\tmerged\teeeeeeee'
      print -r -- $'merged-stale\t104\tmerged\t11111111'
    fi
    ;;
  *)
    print -u2 "unexpected gh: $*"
    exit 64
    ;;
esac
EOF

cat > "$tmpdir/bin/gum" <<'EOF'
#!/bin/zsh
case "$1" in
  choose)
    if [[ "$*" == *'Choose branches'* ]]; then
      if [[ "${GIT_PRUNE_TEST_MODE:-choose}" == all ]]; then
        print -r -- 'Delete all candidates'
      else
        print -r -- 'Choose branches'
      fi
    else
      cat > "$GIT_PRUNE_TEST_SELECTIONS"
      print -r -- $'merged\tPR #101 merged'
    fi
    ;;
  confirm)
    print -r -- "confirm:$*" >> "$GIT_PRUNE_TEST_LOG"
    ;;
  style)
    ;;
  *)
    print -u2 "unexpected gum: $*"
    exit 64
    ;;
esac
EOF
chmod +x "$tmpdir/bin/git" "$tmpdir/bin/gh" "$tmpdir/bin/gum"

export PATH="$tmpdir/bin:$PATH"
export GIT_PRUNE_TEST_LOG="$tmpdir/commands.log"
export GIT_PRUNE_TEST_SELECTIONS="$tmpdir/selections.txt"
source "$repo_root/modules/home-manager/shell/prune-branches.zsh"

: > "$GIT_PRUNE_TEST_LOG"
GIT_PRUNE_TEST_MODE=choose prune-branches
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'fetch:fetch --prune origin'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'gh:api graphql --paginate'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete --force -- merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- closed'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- gone'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- live'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- worktree'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" == *$'merged\tPR #101 merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" == *$'closed\tPR #102 closed'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" == *$'gone\tupstream gone'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" == *$'merged-stale\tPR #104 merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" != *$'live\t'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" != *$'perf-gone\t'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" != *$'worktree\t'* ]]

: > "$GIT_PRUNE_TEST_LOG"
GIT_PRUNE_TEST_MODE=all prune-branches
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete --force -- merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete -- closed'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete -- gone'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete -- merged-stale'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete --force -- merged-stale'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- live'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- worktree'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- perf-gone'* ]]

print -r -- 'prune-branches: PASS'
