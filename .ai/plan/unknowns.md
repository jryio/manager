# Unknowns

Open questions collected while comparing the overview plan against `~/dotfiles` and the local
`nix-darwin` and Home Manager option dumps.

## 01 Packages & Applications

- Which inventory is authoritative: the live machine, the root Brewfile, or the personal and
  work Brewfiles?
- Is the commented-out brewfile step in `work.conf.yaml` intentional or just stale?
- Should `pyenv` and `rbenv` survive the first migration pass, or be replaced immediately by
  devShells?
- Which commercial apps and MAS apps are actually in scope for declarative tracking?
- Do Nix-managed GUI apps need explicit `/Applications` or Dock handling?

## 02 Shell Environment

No topic-level policy unknowns remain. The settled decisions are documented in
`02-shell-environment.md`.

## 03 Dotfiles & App Configuration

- No topic-level intent unknowns remain. Topic 03 policy is settled in
  `03-dotfiles-app-configuration.md`.
- The remaining execution question is whether the target tmux build on macOS will happily
  consume Home Manager's `~/.config/tmux/tmux.conf`, or whether Topic 03 should add a small
  `~/.tmux.conf` compatibility shim that sources the XDG path.
- Neovim bootstrap remains unresolved across Topic 03 and Topic 14: should the first pass
  keep a committed `autoload/plug.vim` copy and rely on a one-time `:PlugInstall`, or should
  some other bootstrap path be documented?
- LunarVim installation and launcher ownership remain unresolved across Topic 03 and Topic
  14. The live `~/.local/bin/lvim` is installer-managed today and does not match the tracked
  wrapper scripts.
- The live television `default_channels.toml` does not map directly to Home Manager's
  `programs.television.channels` output path. Topic 03 still needs a deliberate decision on
  whether to preserve any of those channels or leave them as upstream/default behavior.
- Package ownership for Ghostty, Zed, `gh-dash`, television, jujutsu, tmux, `btop`, and
  `htop` remains blocked on Topics 01 and 15.

## 04 Git Configuration

- Are the missing gitconfig fragments intentionally removed or just not checked in?
- Is `~/.gitconfig.active` still part of the active flow?
- Where are `gitego` and `difftastic` actually installed from today?
- Should the external profile files stay mutable, or move into Nix-managed config?
- Should user identity be expressed via `programs.git.settings.user.*` or kept in include
  fragments?

## 05 SSH Configuration

- What is in the live `~/.ssh/config`, especially for aliases such as `git@zigg:` and
  `git@tdna:`?
- Is `allowed_signers` already in use for SSH-based signing?
- Should the old `ssh-find-agent.sh` fallback survive the migration?
- Is there an unmanaged `~/.ssh/rc` that the tmux comments still expect?
- Should known hosts stay ephemeral or become declarative?

## 06 GPG Configuration

- Should GPG handle SSH auth or only commit and tag signing?
- Are there important untracked `~/.gnupg/*` files that must be preserved?
- Do external Git include files override signing behavior?
- Is smartcard or YubiKey support required?
- Is the Home Manager `services.gpg-agent` surface fully acceptable on this macOS version?

## 07 macOS System Defaults

- Should these defaults be managed machine-wide in nix-darwin or partly per-user in Home
  Manager?
- Is `~/Dropbox/media/screenshots` still the desired screenshot destination?
- Do activation hooks need to restart Finder or SystemUIServer automatically?
- Does the large overview list represent desired target state or just inventory?
- Are any currently enforced defaults set outside the repo and therefore still undiscovered?

## 08 System Services & Daemons

- Which live launchd jobs are still desired and which are stale?
- Should 1Password remain the long-term agent authority?
- For user jobs, should the owner be Home Manager `launchd.agents` or nix-darwin
  `launchd.user.agents`?
- Which vendor-managed background items should remain outside declarative control?
- Which Brewfile is actually authoritative for services?

## 09 Networking & Security

- Which SSH or agent model is the long-term security baseline: 1Password, `gpg-agent`, or
  `ssh-agent`?
- Are there important untracked files such as `~/.ssh/*`, `~/.gnupg/*`, `/etc/hosts`, or
  custom CA certs?
- Should Tailscale come from MAS, Homebrew cask, or a Nix package?
- Do Mullvad or Little Snitch need post-install manual configuration that must be
  documented?
- Should the overview be updated to the local docs’ option names before implementation
  begins?

## 10 Fonts

- The overview claims much larger font inventories than the repo shows; what is the real
  live inventory?
- Should Operator Mono stay, or be replaced with a packaged font from nixpkgs?
- Do the fonts need to be visible to all macOS apps or only to shell and editor tools?
- Should Ghostty and Alacritty both move fully into Home Manager modules now?
- The Apple font smoothing value range differs between plan text and local docs; which one
  is correct here?

## 11 Secrets & Credentials

- Should SSH authentication remain 1Password-backed, or is moving to `gpg-agent` or `ssh-
  agent` acceptable?
- Are `gitego credential` and the external `~/.gitego/profiles/*.gitconfig` files
  intentionally out of band?
- Where are the real sources of truth for `~/.ssh`, `~/.gnupg`, `~/.aws`, and
  `~/.config/gcloud` today?
- Should `shell/op.sh` remain the local secret injection mechanism, or be replaced by an
  encrypted workflow?
- Are there more ignored local secret files following the same pattern as `notify.env`?
- Do you want encrypted secret provisioning in scope now, or only consumer wiring?

## 12 /etc System Files

- Is the overview ahead of the local option dump for `/etc/hosts`, or is the doc snapshot
  incomplete?
- Should the PAM target be `/etc/pam.d/sudo_local` rather than `/etc/pam.d/sudo`?
- Should the existing zsh files be translated semantically into `programs.zsh.*`, or linked
  wholesale first?
- Is `shell/macos.sh` intentionally out of scope for this topic and reserved for the
  defaults topic?
- Are there any live unmanaged `/etc` customizations not visible from the repo?

## 13 Nix Infrastructure Itself

- Where will the Darwin flake actually live?
- Should the current personal and work split become separate Darwin configurations, separate
  Home Manager modules, or parameterized profiles?
- Which current Brew items must remain Homebrew-managed rather than moving to Nix packages?
- What caches, trusted keys, and `allowUnfree` policy are required?
- What GC and optimization cadence is desired for this machine?

## 14 Development Environment

- The `nvm` bootstrap is outside the declarative dotfiles flow; should it survive the
  migration at all?
- `pyenv virtualenv-init` is used, but `pyenv-virtualenv` was not found in the checked
  Brewfiles; is live state drifting from repo state?
- `pre-commit` and Docker Desktop appear in the plan text but not in the checked dotfiles;
  are they installed manually or managed elsewhere?
- Rust tooling is referenced under `~/.rustup`, but no Rust bootstrap was found in the
  checked dev-env files.
- Should the long-term path be flakes plus `direnv`, or a different toolchain manager such
  as `mise`?

## 15 Homebrew Itself

- Whether the canonical package source is the root `Brewfile`, `personal.brewfile`, or
  `work.brewfile`.
- Whether the work profile is intentionally not installing Homebrew packages, since its
  `brewfile` step is commented out.
- How Homebrew itself should be installed long term, since the local nix-darwin docs do not
  document a first-class bootstrap option.
- Whether the future bridge should preserve the current `no-upgrade` posture or adopt more
  aggressive activation cleanup.
- Whether `homebrew.global.brewfile` should replace the linked-`~/.Brewfile` workflow
  completely.

## 16 Remaining Odds & Ends

- Whether system-wide keyboard shortcuts should be modeled through
  `CustomUserPreferences.NSGlobalDomain.NSUserKeyEquivalents` rather than the plan’s direct
  path.
- Whether default-app associations should be handled through raw LaunchServices plist data
  or an external tool such as `duti`.
- What the actual live System Settings state is for the excluded or manual items, since the
  dotfiles do not represent it.
- Whether `timemachineeditor` still needs to be preserved at all.
- Whether wallpaper should stay manual or move into Home Manager `programs.desktoppr`.
