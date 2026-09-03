# Commit the current worktree through OMP with the repository commit policy.
# The function has no user flags so every real invocation pushes and skips changelogs.
commit() {
  omp commit --push --no-changelog --context '
YOU MUST intelligently inspect staged and unstaged files in this branch or worktree with git status. Read their contents, then batch related changes into logical commits.

You MUST use the Conventional Commits specification for every commit title. Titles MUST be lowercase and at most 80 characters.

Not every commit needs a detailed message. Use your judgment. For commits that need one, use the /technical-writing skill to write the body in complete English prose.

NEVER drop or remove changed files.
NEVER add ignored files, including node_modules, build artifacts, or package dependencies.
ALWAYS create and apply commits carefully.
ALWAYS group and write commits with the Conventional Commits pattern.
ALWAYS create multiple commits for large diffs that span semantically different changes, files, or packages.
ALWAYS create one commit for trivial changes, such as bulk renames, bulk refactors, or basic tooling version changes.
'
}
