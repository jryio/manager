# 17 Brew/Nix Shadowing — Uninstall Plan

Source: audit run 2026-08-13 against AVA, recorded in `DECISIONS.md` under
`[lazyvim-cutover-2026-08-13]` and this session's entry.
Status: written, not executed.
Result type: operator runbook.

## Summary

D5 moved eight CLIs from Homebrew to Nix by deleting them from
`modules/darwin/homebrew.nix` and relying on a Home Manager `programs.*` module
instead. D3 (`cleanup = "none"`) means undeclaring a formula does not uninstall
it, and `/opt/homebrew/bin` precedes the Nix profile on `$PATH`. The result is
that on AVA the Nix builds are installed, linked, and never executed — every one
of these commands still runs the Homebrew copy.

A machine that has never had those formulae (GROT, or any fresh install) runs
the Nix builds. So the same commit produces different binaries on different
hosts, which is the opposite of what this repo is for.

## Evidence

Thirty-four Nix-provided commands are shadowed by `/opt/homebrew/{bin,sbin}`.
Eight of them are the D5 set; the rest are the GnuPG family and git's helper
binaries (`git-upload-pack`, `git-shell`, `scalar`, …), which come along with
`git` and `gnupg`.

| command | live (brew) | declared (nix) |
| --- | --- | --- |
| `btop` | 1.4.0 | 1.4.5 |
| `gh` | 2.96.0 | 2.83.2 |
| `git` | 2.50.1 | 2.51.2 |
| `jj` | 0.34.0 | 0.35.0 |
| `tv` (television) | 0.13.12 | 0.13.10 |
| `vale` | 3.13.0 | 3.14.1 |
| `htop` | installed, shell-aliased to `btm` | 3.4.1 |
| `tmux` | wins | shadowed |

`brew uses --installed` is empty for all eight: nothing else on the machine
depends on them.

## Decision to make first

`gnupg` is a *declared* brew, so its shadowing is deliberate — but
`modules/home-manager/gpg.nix` also pulls a Nix gnupg that can never run, and
brew's 2.5.20 is ahead of nixpkgs' 2.4.9. Two coherent answers:

- **Keep gnupg on brew** (recommended, no work): drop the Nix gnupg from
  `gpg.nix` so the config stops claiming something untrue. The GnuPG family
  disappears from the shadow list without touching the machine.
- **Move gnupg to Nix**: uninstall the brew formula with the eight below and
  drop it from `homebrew.nix`. This touches the GPG signing path, which every
  commit in this repo depends on, so it wants its own change and its own
  validation.

Do not bundle the gnupg decision with the eight.

## Plan

Run as the Homebrew owner (CASE), not `testaccount`: Homebrew is per-user state
and nix-darwin already drives `brew bundle` as CASE.

1. **Confirm nothing depends on them.** Expect empty output.

       for f in btop gh git htop jj tmux television vale; do
         printf '%-12s %s\n' "$f" "$(brew uses --installed "$f")"
       done

2. **Record what will be lost.** Homebrew keeps no history once a keg is gone.

       brew list --versions btop gh git htop jj tmux television vale \
         > ~/.local/state/manager/brew-uninstalled-$(date +%Y%m%d).txt

3. **Check the two that carry per-user state.**
   - `gh`: authentication lives in `~/.config/gh/hosts.yml`, outside the keg, so
     it survives. Verify with `gh auth status` afterwards.
   - `git`: `/opt/homebrew/bin/git` is what the shell, `gitego`, and every tool
     that shells out currently use. Nix's git is 2.51.2 and reads the same
     `~/.config/git/config`. Confirm `git config --list --show-origin | head`
     resolves identically after the swap.

4. **Uninstall.**

       brew uninstall btop gh git htop jj tmux television vale

5. **Verify the Nix builds took over.** Every path below must be under
   `/etc/profiles/per-user/` or `/nix/store`, and no command may vanish.

       for c in btop gh git htop jj tmux tv vale; do
         printf '%-6s %s\n' "$c" "$(command -v $c)"
       done

6. **Re-check the shadow list is empty** apart from the GnuPG family, pending
   the decision above.

7. **Switch and smoke.** `darwin-rebuild switch` under `testaccount`, then
   `scripts/smoke-testaccount.sh`. The harness asserts a brew-leaves floor of 20;
   removing eight from ~99 does not approach it.

8. **Sanity-drive the two that matter interactively**: a real commit (git +
   gitego + GPG signing), and `tmux` attaching to an existing session — a
   running server keeps the old binary until it is killed, so
   `tmux kill-server` or a logout is part of the change, not a surprise after
   it.

## Rollback

`brew install <formula>` restores any of them; the versions recorded in step 2
pin what was there. Nothing in the repo changes, so there is no commit to
revert — this plan only removes duplicates that the config already says should
not exist.

## Not in scope

- Reordering `$PATH` to put the Nix profile ahead of Homebrew. It would fix this
  class permanently but silently changes precedence for the other ~99 brews.
- The reverse choice — re-declaring the eight as brews and dropping the Home
  Manager modules — which is a real option if brew's newer `gh` and `tv` matter
  more than one source of truth.
