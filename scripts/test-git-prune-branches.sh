#!/bin/zsh
set -euo pipefail

repo_root=${0:A:h:h}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-prune-branches-test.XXXXXX")
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
    ;;
  worktree)
    print -r -- 'worktree /tmp/repo'
    print -r -- 'branch refs/heads/main'
    print -r -- 'worktree /tmp/linked'
    print -r -- 'branch refs/heads/worktree'
    ;;
  for-each-ref)
    case "$*" in
      *'%(refname)'*'refs/remotes')
        print -r -- 'refs/remotes/origin/HEAD'
        print -r -- 'refs/remotes/origin/main'
        print -r -- 'refs/remotes/origin/live'
        ;;
      *'%(refname:short)%09%(upstream:track)'*)
        print -r -- $'main\t[origin/main]'
        print -r -- $'merged\t'
        print -r -- $'closed\t'
        print -r -- $'gone\t[gone]'
        print -r -- $'live\t[origin/live]'
        print -r -- $'worktree\t'
        ;;
      *'%(refname:short)'*'refs/heads')
        print -r -- main
        print -r -- merged
        print -r -- closed
        print -r -- gone
        print -r -- live
        print -r -- worktree
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
    print -r -- $'merged\t101\tmerged'
    print -r -- $'closed\t102\tclosed'
    print -r -- $'worktree\t103\tmerged'
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
source "$repo_root/modules/home-manager/shell/git-prune-branches.zsh"

: > "$GIT_PRUNE_TEST_LOG"
GIT_PRUNE_TEST_MODE=choose git-prune-branches
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'fetch:fetch --all --prune'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'gh:api graphql --paginate'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete -- merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- closed'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- gone'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- live'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- worktree'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" == *$'merged\tPR #101 merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" == *$'closed\tPR #102 closed'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" == *$'gone\tupstream gone'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" != *$'live\t'* ]]
[[ "$(<"$GIT_PRUNE_TEST_SELECTIONS")" != *$'worktree\t'* ]]

: > "$GIT_PRUNE_TEST_LOG"
GIT_PRUNE_TEST_MODE=all git-prune-branches
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete -- merged'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete -- closed'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" == *'delete:branch --delete -- gone'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- live'* ]]
[[ "$(<"$GIT_PRUNE_TEST_LOG")" != *'delete:branch --delete -- worktree'* ]]

print -r -- 'git-prune-branches: PASS'
