Complete Surface Area of a macOS System Under Declarative Management

How the Four Pieces Fit Together

┌────────────────────────┬────────────────┬─────────────────────────────────────────────────────────────────────────┬────────────────────────────┐
│ Layer │ Tool │ Scope │ Activation │
├────────────────────────┼────────────────┼─────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ System-level macOS │ nix-darwin │ Global /etc, launchd daemons, system defaults, system packages, macOS │ darwin-rebuild switch │
│ config │ │ settings that need sudo │ │
├────────────────────────┼────────────────┼─────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ User-level config & │ │ ~/.config/\*, dotfiles, user packages, shell config, user │ Part of nix-darwin or │
│ dotfiles │ Home Manager │ services/agents │ standalone home-manager │
│ │ │ │ switch │
├────────────────────────┼────────────────┼─────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Package management / │ Nix (the │ Provides every package. The engine underneath both nix-darwin and Home │ │
│ build infrastructure │ package │ Manager │ nix-env, flakes, overlays │
│ │ manager) │ │ │
├────────────────────────┼────────────────┼─────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ │ Not applicable │ NixOS is a Linux distro. On Mac, nix-darwin fills the "system config" │ │
│ NixOS │ on macOS │ role. NixOS concepts (modules, options, configuration.nix) are reused │ — │
│ │ │ by nix-darwin, but you don't run NixOS. │ │
└────────────────────────┴────────────────┴─────────────────────────────────────────────────────────────────────────┴────────────────────────────┘

The dependency chain:

Nix (package manager)
├── nix-darwin (system-level macOS management)
│ └── home-manager (as a nix-darwin module, user-level management)
└── Flake (single flake.nix entry point ties it all together)

One flake.nix → calls nix-darwin → which embeds home-manager as a module → darwin-rebuild switch applies everything atomically.

---

EXHAUSTIVE SURFACE AREA

Research Files

- [01-packages-applications.md](./01-packages-applications.md)
- [02-shell-environment.md](./02-shell-environment.md)
- [03-dotfiles-app-configuration.md](./03-dotfiles-app-configuration.md)
- [04-git-configuration.md](./04-git-configuration.md)
- [05-ssh-configuration.md](./05-ssh-configuration.md)
- [06-gpg-configuration.md](./06-gpg-configuration.md)
- [07-macos-system-defaults.md](./07-macos-system-defaults.md)
- [08-system-services-daemons.md](./08-system-services-daemons.md)
- [09-networking-security.md](./09-networking-security.md)
- [10-fonts.md](./10-fonts.md)
- [11-secrets-credentials.md](./11-secrets-credentials.md)
- [12-etc-system-files.md](./12-etc-system-files.md)
- [13-nix-infrastructure.md](./13-nix-infrastructure.md)
- [14-development-environment.md](./14-development-environment.md)
- [15-homebrew-itself.md](./15-homebrew-itself.md)
- [16-remaining-odds-ends.md](./16-remaining-odds-ends.md)
- [unknowns.md](./unknowns.md)

1.  PACKAGES & APPLICATIONS

┌─────────────────────────────────────────────┬───────────────┬───────────────────────────────────────────────┬──────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ CLI tools (335 brew formulas: bat, fzf, │ │ nix-darwin environment.systemPackages or Home │ │
│ ripgrep, jq, neovim, tmux, btop, gh, │ Homebrew │ Manager home.packages │ Nix packages from nixpkgs │
│ lazygit, jj, deno, bun, go, uv, etc.) │ │ │ │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ GUI apps via cask (16 casks: ghostty, │ │ nix-darwin homebrew.casks (nix-darwin can │ environment.systemPackages or │
│ alacritty, 1password-cli, wireshark, etc.) │ Homebrew Cask │ declaratively manage Homebrew) or native nix │ homebrew.casks │
│ │ │ packages where available │ │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ Mac App Store apps (Amphetamine, 1Blocker, │ │ nix-darwin homebrew.masApps (uses mas CLI │ homebrew.masApps = { "Things3" = │
│ Things3, Day One, Dark Noise, Focused Work, │ MAS manual │ under the hood) │ 904280696; } │
│ etc.) │ │ │ │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ Large commercial GUI apps (Adobe Lightroom, │ │ │ │
│ Microsoft Excel/Word, Figma, Slack, │ Manual / │ nix-darwin homebrew.casks │ Not all have nix packages; cask │
│ Discord, Spotify, Docker, Arc, Linear, │ Homebrew Cask │ │ is pragmatic │
│ Obsidian, ChatGPT, etc.) │ │ │ │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ Language runtimes (python@3.12, ruby, go, │ Homebrew + │ Home Manager or nix-darwin packages; nix │ programs.pyenv.enable or │
│ node, elixir/erlang, deno, bun, dotnet@9) │ pyenv + rbenv │ devShells replace version managers │ per-project flake.nix devShells │
│ │ + nvm │ │ │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ Version managers (pyenv, rbenv, nvm) │ Manual │ Eliminated — replaced by nix devShells │ nix develop with pinned versions │
│ │ │ per-project │ │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ Xcode / Xcode CLT │ Manual │ Cannot be nix-managed — must remain manual │ Excluded; document as │
│ │ │ (Apple licensing) │ prerequisite │
├─────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────┼──────────────────────────────────┤
│ TeX (mactex) │ Homebrew cask │ nix-darwin homebrew.casks or texlive nix │ Either approach works │
│ │ │ packages │ │
└─────────────────────────────────────────────┴───────────────┴───────────────────────────────────────────────┴──────────────────────────────────┘

2.  SHELL ENVIRONMENT

┌──────────────────────┬─────────────────────────────────────┬────────────────────────────────────────────────┬──────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Default shell │ System default │ nix-darwin users.users.CASE.shell or keep │ environment.shells │
│ (/bin/zsh) │ │ system zsh │ │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ .zshrc │ Symlink → ~/dotfiles/shell/zshrc │ Home Manager programs.zsh.enable + initExtra │ Generates .zshrc declaratively │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ .zprofile │ Symlink → ~/dotfiles/shell/zprofile │ Home Manager programs.zsh.profileExtra │ Part of zsh module │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ .zshenv │ Direct file │ Home Manager programs.zsh.envExtra │ Part of zsh module │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ .bashrc / │ Direct files │ Home Manager programs.bash │ If bash is used at all │
│ .bash_profile │ │ │ │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Oh-My-Zsh │ ~/dotfiles/oh-my-zsh │ Home Manager programs.zsh.oh-my-zsh │ Built-in module with │
│ │ │ │ theme/plugin config │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Shell aliases │ Inside zshrc │ Home Manager programs.zsh.shellAliases │ Declarative map │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Shell functions │ ~/dotfiles/functions/ │ Home Manager programs.zsh.initExtra or │ Source function files │
│ │ │ home.file │ │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Environment │ Scattered │ Home Manager home.sessionVariables │ { EDITOR = "zed --wait"; } │
│ variables │ │ │ │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ PATH construction │ Accumulated from brew, pyenv, │ Nix profile automatically + Home Manager │ Nix handles PATH for its │
│ │ rbenv, etc. │ home.sessionPath │ packages │
├──────────────────────┼─────────────────────────────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Prompt / theme │ Zsh theme in dotfiles │ Home Manager programs.starship or custom theme │ Declarative prompt config │
└──────────────────────┴─────────────────────────────────────┴────────────────────────────────────────────────┴──────────────────────────────────┘

3.  DOTFILES & APP CONFIGURATION

┌──────────────────────────────────────────┬───────────────┬────────────────────────────────────────────────────┬─────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/ghostty/config │ Manual / │ Home Manager home.file.".config/ghostty/config" or │ File content declared in nix │
│ │ dotfiles │ xdg.configFile │ │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/alacritty/alacritty.toml │ Manual │ Home Manager programs.alacritty │ Built-in module with settings │
│ │ │ │ attrset │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/nvim/ (init.vim, config.lua, │ Manual │ Home Manager programs.neovim │ Plugin management, extraConfig, │
│ plugins) │ │ │ extraLuaConfig │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/zed/settings.json + │ Manual │ Home Manager home.file or xdg.configFile │ Declare JSON content │
│ keymap.json │ │ │ │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.tmux.conf + ~/.tmux-osx.conf │ Manual │ Home Manager programs.tmux │ Built-in module │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/btop/ │ Manual │ Home Manager home.file or xdg.configFile │ File content │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/gh/ (GitHub CLI) │ Manual │ Home Manager programs.gh │ Built-in module │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/gh-dash/ │ Manual │ Home Manager xdg.configFile │ File content │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/htop/ │ Manual │ Home Manager programs.htop │ Built-in module │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/git/ or ~/.gitconfig │ Manual │ Home Manager programs.git │ See Git section below │
│ │ dotfile │ │ │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/vale/ │ Manual │ Home Manager xdg.configFile │ File content │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/television/ │ Manual │ Home Manager xdg.configFile │ File content │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/jj/ (Jujutsu VCS) │ Manual │ Home Manager xdg.configFile │ File content │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/.config/lvim/ (LunarVim) │ Manual │ Home Manager home.file │ File content │
├──────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────────┼─────────────────────────────────┤
│ ~/dotfiles/ (entire dotfiles repo) │ Dotbot │ Replaced entirely by Home Manager │ Home Manager IS your dotfile │
│ │ │ │ manager │
└──────────────────────────────────────────┴───────────────┴────────────────────────────────────────────────────┴─────────────────────────────────┘

4.  GIT CONFIGURATION

┌─────────────────────────────────────────────┬───────────────┬────────────────────────────────────────────────┬──────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ user.name, user.email │ .gitconfig │ Home Manager programs.git.userName / userEmail │ Direct options │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ GPG signing (commit.gpgsign=true, │ .gitconfig │ Home Manager programs.git.signing │ { key = "..."; signByDefault = │
│ gpg.program=gpg) │ │ │ true; } │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Core editor (zed --wait) │ .gitconfig │ Home Manager │ Nested attrset │
│ │ │ programs.git.extraConfig.core.editor │ │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ LFS config │ .gitconfig │ Home Manager programs.git.lfs.enable │ Boolean │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Diff tool (difftastic) │ .gitconfig │ Home Manager programs.git.difftastic.enable │ Built-in difftastic support │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ URL rewrites (insteadOf for github SSH) │ .gitconfig │ Home Manager programs.git.extraConfig.url │ Nested attrset │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Pull rebase default │ .gitconfig │ Home Manager │ Nested attrset │
│ │ │ programs.git.extraConfig.pull.rebase │ │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Global .gitignore │ ~/.gitignore │ Home Manager programs.git.ignores │ List of patterns │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Credential helper (gitego) │ .gitconfig │ Home Manager │ Nested attrset │
│ │ │ programs.git.extraConfig.credential │ │
├─────────────────────────────────────────────┼───────────────┼────────────────────────────────────────────────┼──────────────────────────────────┤
│ Git hooks (global) │ Not │ Home Manager programs.git.hooks │ If needed │
│ │ configured │ │ │
└─────────────────────────────────────────────┴───────────────┴────────────────────────────────────────────────┴──────────────────────────────────┘

5.  SSH CONFIGURATION

┌─────────────────────────────────────────────────┬───────────────────┬────────────────────────────────────────────┬───────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────────────────────────────────┼───────────────────┼────────────────────────────────────────────┼───────────────────────────────┤
│ ~/.ssh/config (hosts, 1Password agent, identity │ Manual file │ Home Manager programs.ssh │ matchBlocks, extraConfig │
│ files) │ │ │ │
├─────────────────────────────────────────────────┼───────────────────┼────────────────────────────────────────────┼───────────────────────────────┤
│ ~/.ssh/allowed_signers │ Manual │ Home Manager │ File content │
│ │ │ home.file.".ssh/allowed_signers" │ │
├─────────────────────────────────────────────────┼───────────────────┼────────────────────────────────────────────┼───────────────────────────────┤
│ SSH agent forwarding / 1Password agent socket │ Symlink │ Home Manager programs.ssh │ extraConfig │
├─────────────────────────────────────────────────┼───────────────────┼────────────────────────────────────────────┼───────────────────────────────┤
│ Known hosts │ Auto-accumulated │ Not managed (ephemeral) │ Excluded │
├─────────────────────────────────────────────────┼───────────────────┼────────────────────────────────────────────┼───────────────────────────────┤
│ SSH keys themselves │ Manual / │ Not managed by nix (secrets!) │ Use sops-nix or agenix for │
│ │ 1Password │ │ secrets │
└─────────────────────────────────────────────────┴───────────────────┴────────────────────────────────────────────┴───────────────────────────────┘

6.  GPG CONFIGURATION

┌───────────────────────────────┬───────────┬───────────────────────────────────────────────────────────┬─────────────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├───────────────────────────────┼───────────┼───────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ ~/.gnupg/ (keyring, config) │ Manual │ Home Manager programs.gpg │ homedir, settings, etc. │
├───────────────────────────────┼───────────┼───────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ gpg-agent.conf │ Manual │ Home Manager services.gpg-agent (Linux) or programs.gpg │ On macOS: pinentry-mac config via │
│ │ │ config │ home.file │
├───────────────────────────────┼───────────┼───────────────────────────────────────────────────────────┼─────────────────────────────────────────┤
│ Pinentry program │ Homebrew │ Home Manager / nix-darwin package + config │ Package + gpg-agent config │
│ (pinentry-mac) │ │ │ │
└───────────────────────────────┴───────────┴───────────────────────────────────────────────────────────┴─────────────────────────────────────────┘

7.  macOS SYSTEM DEFAULTS (defaults write)

This is where nix-darwin shines. Every defaults write command becomes a declarative option:

Global Preferences

┌────────────────────────────┬────────────────────────────┬─────────────────────────────────────────────────────────────────┐
│ Setting │ Current Value │ nix-darwin Option │
├────────────────────────────┼────────────────────────────┼─────────────────────────────────────────────────────────────────┤
│ Dark mode │ AppleInterfaceStyle = Dark │ defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark" │
├────────────────────────────┼────────────────────────────┼─────────────────────────────────────────────────────────────────┤
│ Language │ en-US, en, he-US │ defaults.NSGlobalDomain.AppleLanguages = ["en-US" "en" "he-US"] │
├────────────────────────────┼────────────────────────────┼─────────────────────────────────────────────────────────────────┤
│ Key repeat speed │ KeyRepeat = 2 │ defaults.NSGlobalDomain.KeyRepeat = 2 │
├────────────────────────────┼────────────────────────────┼─────────────────────────────────────────────────────────────────┤
│ Initial key repeat delay │ InitialKeyRepeat = 15 │ defaults.NSGlobalDomain.InitialKeyRepeat = 15 │
├────────────────────────────┼────────────────────────────┼─────────────────────────────────────────────────────────────────┤
│ Press-and-hold disabled │ Not set (default) │ defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false │
├────────────────────────────┼────────────────────────────┼─────────────────────────────────────────────────────────────────┤
│ Show scroll bars │ WhenScrolling │ defaults.NSGlobalDomain.AppleShowScrollBars = "WhenScrolling" │
├────────────────────────────┼────────────────────────────┼─────────────────────────────────────────────────────────────────┤
│ Scroll direction (natural) │ System default │ defaults.NSGlobalDomain."com.apple.swipescrolldirection" │
└────────────────────────────┴────────────────────────────┴─────────────────────────────────────────────────────────────────┘

Dock

┌─────────────────────────┬─────────────────────────────┬────────────────────────────────────────────────────────┐
│ Setting │ Current Value │ nix-darwin Option │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Auto-hide │ autohide = 1 │ system.defaults.dock.autohide = true │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Launch animation │ launchanim = 0 │ system.defaults.dock.launchanim = false │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Minimize effect │ scale │ system.defaults.dock.mineffect = "scale" │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Minimize to application │ 1 │ system.defaults.dock.minimize-to-application = true │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Magnification │ 0 │ system.defaults.dock.magnification = false │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Expose group apps │ 1 │ system.defaults.dock.expose-group-apps = true │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Persistent apps │ Ghostty + others │ system.defaults.dock.persistent-apps (limited support) │
├─────────────────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ Hot corners │ TL=disabled, others=default │ system.defaults.dock.wvous-tl-corner etc. │
└─────────────────────────┴─────────────────────────────┴────────────────────────────────────────────────────────┘

Finder

┌────────────────────┬──────────────────────────┬──────────────────────────────────────────────────────┐
│ Setting │ Current Value │ nix-darwin Option │
├────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────┤
│ Show hidden files │ AppleShowAllFiles = TRUE │ system.defaults.finder.AppleShowAllFiles = true │
├────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────┤
│ Show extensions │ Not read │ system.defaults.finder.AppleShowAllExtensions = true │
├────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────┤
│ Default view style │ Column view │ system.defaults.finder.FXPreferredViewStyle = "clmv" │
├────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────┤
│ Show path bar │ Not read │ system.defaults.finder.ShowPathbar = true │
├────────────────────┼──────────────────────────┼──────────────────────────────────────────────────────┤
│ Show status bar │ Not read │ system.defaults.finder.ShowStatusBar = true │
└────────────────────┴──────────────────────────┴──────────────────────────────────────────────────────┘

Trackpad

┌───────────────────────────┬────────────────────────┬────────────────────────────────────────────────────┐
│ Setting │ Current Value │ nix-darwin Option │
├───────────────────────────┼────────────────────────┼────────────────────────────────────────────────────┤
│ Tap to click │ Clicking = 1 │ system.defaults.trackpad.Clicking = true │
├───────────────────────────┼────────────────────────┼────────────────────────────────────────────────────┤
│ Dragging │ Dragging = 0 │ system.defaults.trackpad.Dragging = false │
├───────────────────────────┼────────────────────────┼────────────────────────────────────────────────────┤
│ Right-click (two-finger) │ TrackpadRightClick = 1 │ system.defaults.trackpad.TrackpadRightClick = true │
├───────────────────────────┼────────────────────────┼────────────────────────────────────────────────────┤
│ All multi-finger gestures │ Various │ system.defaults.trackpad.\* │
└───────────────────────────┴────────────────────────┴────────────────────────────────────────────────────┘

Other macOS Defaults

┌───────────────────────────┬──────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────┐
│ Domain │ Settings │ nix-darwin │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.screencapture │ Location, format, shadow │ system.defaults.screencapture._ │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.screensaver │ Idle time, require password │ system.defaults.screensaver._ │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.menuextra.clock │ Format, flash separators │ system.defaults.menuExtraClock._ │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.controlcenter │ Visible menu bar items (Bluetooth, WiFi, Sound, Battery, │ system.defaults.controlcenter._ │
│ │ Focus, etc.) │ │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.WindowManager │ Stage Manager, tiling │ system.defaults.WindowManager._ │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.spaces │ Spans displays, auto-rearrange │ system.defaults.spaces._ │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.Safari │ Developer menu, tab layout │ system.defaults.Safari._ (limited) │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.desktopservices │ .DS_Store on network/USB │ system.defaults.CustomUserPreferences │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.LaunchServices │ Quarantine warnings │ system.defaults.LaunchServices._ │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ com.apple.SoftwareUpdate │ Auto-check, auto-download │ system.defaults.SoftwareUpdate.\* │
├───────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Per-app defaults │ Any app's defaults domain │ system.defaults.CustomUserPreferences."com.app.bundle" │
└───────────────────────────┴──────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────┘

8.  SYSTEM SERVICES & DAEMONS

┌────────────────────────────────────────┬─────────────────────────────────────────┬────────────────────────────────────┬──────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├────────────────────────────────────────┼─────────────────────────────────────────┼────────────────────────────────────┼──────────────────────────┤
│ │ 27 plists (Little Snitch, Backblaze, │ │ Declarative plist │
│ /Library/LaunchDaemons/ (system-wide) │ Docker, Malwarebytes, Mullvad, │ nix-darwin launchd.daemons │ generation │
│ │ PostgreSQL, ngrok, etc.) │ │ │
├────────────────────────────────────────┼─────────────────────────────────────────┼────────────────────────────────────┼──────────────────────────┤
│ /Library/LaunchAgents/ (system-wide │ 15 plists (Google updaters, Logi │ nix-darwin launchd.agents │ Declarative plist │
│ user agents) │ Options, GPG, XQuartz, etc.) │ │ generation │
├────────────────────────────────────────┼─────────────────────────────────────────┼────────────────────────────────────┼──────────────────────────┤
│ │ 25 plists (Backblaze, iStat, Dropbox, │ Home Manager launchd.agents (via │ Declarative plist │
│ ~/Library/LaunchAgents/ (user agents) │ Watchman, MySQL, old PostgreSQL, Zoom, │ nix-darwin) │ generation │
│ │ etc.) │ │ │
├────────────────────────────────────────┼─────────────────────────────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Homebrew services (mysql, │ │ nix-darwin launchd.daemons or Home │ Replace brew services │
│ postgresql@14, redis, kafka, caddy, │ brew services │ Manager launchd.agents │ with nix launchd │
│ black) │ │ │ definitions │
├────────────────────────────────────────┼─────────────────────────────────────────┼────────────────────────────────────┼──────────────────────────┤
│ │ │ nix-darwin (partial — macOS login │ Some via launchd, others │
│ Login items / background items │ BTM-managed (sfltool) │ items are hard to declaratively │ manual │
│ │ │ manage) │ │
└────────────────────────────────────────┴─────────────────────────────────────────┴────────────────────────────────────┴──────────────────────────┘

9.  NETWORKING & SECURITY

┌─────────────────────────┬────────────────────────┬────────────────────────────────────────────────────────────────┬─────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ Firewall state │ Disabled │ nix-darwin system.defaults.alf.globalstate │ 0 = off, 1 = on, 2 = block │
│ │ │ │ all │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ FileVault │ On │ Cannot be nix-managed (requires recovery key, manual setup) │ Document as prerequisite │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ Little Snitch (network │ System extension, │ Cannot be nix-managed (kernel extension) │ Install via cask, config is │
│ filter) │ active │ │ manual │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ Mullvad VPN │ Installed, daemon │ nix-darwin homebrew.casks for install; daemon is │ Install only │
│ │ running │ vendor-managed │ │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ Tailscale │ Installed │ nix-darwin package or cask │ Install only; auth is │
│ │ │ │ manual │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ DNS settings │ System default │ nix-darwin networking.dns │ ["1.1.1.1" "8.8.8.8"] │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ Hostname │ AVA │ nix-darwin networking.hostName, networking.computerName, │ All three set declaratively │
│ │ │ networking.localHostName │ │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ /etc/hosts │ System default │ nix-darwin networking.hosts │ Attrset of hostname → IPs │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ Proxy configuration │ Not configured │ nix-darwin networking.proxy │ If needed │
├─────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┼─────────────────────────────┤
│ Network locations / │ Hardware-dependent │ Not nix-managed │ Too hardware-specific │
│ interfaces │ │ │ │
└─────────────────────────┴────────────────────────┴────────────────────────────────────────────────────────────────┴─────────────────────────────┘

10. FONTS

┌─────────────────────────────────┬──────────────┬──────────────────────────────────────────────────────────────┬─────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────┼─────────────────────────────────┤
│ User fonts (~/Library/Fonts/, │ Manual │ Home Manager fonts.fontconfig + home.packages with nerd │ pkgs.nerd-fonts.\*, custom font │
│ 230 fonts) │ install │ fonts, etc. │ packages │
├─────────────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────┼─────────────────────────────────┤
│ System fonts (/Library/Fonts/, │ System │ nix-darwin fonts.packages │ [ pkgs.inter │
│ 90 fonts) │ default │ │ pkgs.jetbrains-mono ] │
├─────────────────────────────────┼──────────────┼──────────────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Font smoothing / antialiasing │ macOS │ nix-darwin system.defaults.NSGlobalDomain.AppleFontSmoothing │ Integer 0-3 │
│ │ default │ │ │
└─────────────────────────────────┴──────────────┴──────────────────────────────────────────────────────────────┴─────────────────────────────────┘

11. SECRETS & CREDENTIALS

┌─────────────────────┬──────────────────────────────┬───────────────────────────────────────────────────────┬────────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────┼────────────────────────────────────┤
│ SSH private keys │ ~/.ssh/ files + 1Password │ Never in nix — use sops-nix or agenix │ Encrypted secrets decrypted at │
│ │ agent │ │ activation │
├─────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────┼────────────────────────────────────┤
│ GPG private keys │ ~/.gnupg/ │ Never in nix — manual or sops-nix │ Keep out of nix store │
├─────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────┼────────────────────────────────────┤
│ API tokens, .env │ Various locations │ sops-nix for system secrets │ Encrypted in repo, decrypted at │
│ files │ │ │ build │
├─────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────┼────────────────────────────────────┤
│ macOS Keychain │ System managed │ Not nix-managed │ Cannot be declaratively managed │
├─────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────┼────────────────────────────────────┤
│ 1Password │ App + CLI + SSH agent │ nix-darwin cask + cli package; integration config via │ Install declaratively, auth manual │
│ │ │ Home Manager │ │
├─────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────┼────────────────────────────────────┤
│ AWS/GCloud │ ~/.config/gcloud/, ~/.aws/ │ Not in nix (runtime auth state) │ Excluded │
│ credentials │ │ │ │
└─────────────────────┴──────────────────────────────┴───────────────────────────────────────────────────────┴────────────────────────────────────┘

12. /etc/ SYSTEM FILES

┌─────────────────────────┬──────────────────────┬───────────────────────────────────────────┬─────────────────────────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────────┼──────────────────────┼───────────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ /etc/shells │ System default │ nix-darwin environment.shells │ Adds nix-managed shells │
├─────────────────────────┼──────────────────────┼───────────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ /etc/nix/nix.conf │ Will be created by │ nix-darwin nix.settings │ experimental-features, substituters, trusted-users, │
│ │ nix │ │ etc. │
├─────────────────────────┼──────────────────────┼───────────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ /etc/zshrc, │ System default │ nix-darwin modifies these to source nix │ Automatic │
│ /etc/zprofile │ │ paths │ │
├─────────────────────────┼──────────────────────┼───────────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ /etc/hosts │ System default │ nix-darwin networking.hosts │ Declarative host entries │
├─────────────────────────┼──────────────────────┼───────────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ /etc/pam.d/sudo │ System default │ nix-darwin security.pam │ E.g., Touch ID for sudo │
├─────────────────────────┼──────────────────────┼───────────────────────────────────────────┼─────────────────────────────────────────────────────┤
│ /etc/sudoers │ System default │ Partially — nix-darwin can add rules │ Limited support │
└─────────────────────────┴──────────────────────┴───────────────────────────────────────────┴─────────────────────────────────────────────────────┘

13. NIX INFRASTRUCTURE ITSELF

┌───────────────────────────────────────┬───────────────────────────────────────┬───────────────────────────────────────────┐
│ What │ Managed By │ Nix Mechanism │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Nix daemon configuration │ nix-darwin nix.settings │ max-jobs, cores, sandbox, etc. │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Garbage collection schedule │ nix-darwin nix.gc │ automatic = true; interval = { Day = 7; } │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Binary caches / substituters │ nix-darwin nix.settings.substituters │ Cachix, official cache │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Flake registry │ nix-darwin nix.registry │ Pin nixpkgs, etc. │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Nix store optimization │ nix-darwin nix.optimise │ Auto hard-link dedup │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Allowed/trusted users │ nix-darwin nix.settings.trusted-users │ ["root" "CASE"] │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Overlays (custom packages, overrides) │ Flake overlays │ Modify/add packages │
├───────────────────────────────────────┼───────────────────────────────────────┼───────────────────────────────────────────┤
│ Nixpkgs config (allowUnfree, etc.) │ nix-darwin nixpkgs.config │ { allowUnfree = true; } │
└───────────────────────────────────────┴───────────────────────────────────────┴───────────────────────────────────────────┘

14. DEVELOPMENT ENVIRONMENT

┌─────────────────────────────┬─────────────────────────┬────────────────────────────────────────────────────┬────────────────────────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├─────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼────────────────────────────────────┤
│ Per-project toolchains │ pyenv/rbenv/nvm + │ Nix flakes per-project devShell │ nix develop with direnv │
│ │ Brewfile │ │ │
├─────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼────────────────────────────────────┤
│ direnv integration │ Not detected │ Home Manager programs.direnv + │ Auto-activates nix devShells on cd │
│ │ │ programs.direnv.nix-direnv │ │
├─────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼────────────────────────────────────┤
│ Docker │ Docker Desktop app │ nix-darwin homebrew.casks = ["docker"] │ Install only; runtime state not │
│ │ │ │ managed │
├─────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼────────────────────────────────────┤
│ Editor LSPs, formatters, │ Various │ Per-project devShell or Home Manager global │ Nix packages │
│ linters │ │ │ │
├─────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼────────────────────────────────────┤
│ Pre-commit hooks │ pre-commit brew package │ Per-project devShell │ pkgs.pre-commit │
└─────────────────────────────┴─────────────────────────┴────────────────────────────────────────────────────┴────────────────────────────────────┘

15. HOMEBREW ITSELF (MANAGED BY NIX-DARWIN)

nix-darwin has a homebrew module that declaratively manages Homebrew:

homebrew = {
enable = true;
onActivation = {
autoUpdate = true;
cleanup = "zap"; # Remove anything not declared
upgrade = true;
};
taps = [ "homebrew/cask" ];
brews = [ /* formulas that have no nix equivalent */ ];
casks = [
"1password" "arc" "docker" "discord" "figma" "ghostty"
"linear" "obsidian" "slack" "spotify" "zed" /* ... */
];
masApps = {
"Things3" = 904280696;
"Amphetamine" = 937984704;
/_ ... _/
};
};

This is the pragmatic bridge — nix-darwin manages Homebrew declaratively for GUI apps that don't have nix packages.

16. REMAINING ODDS & ENDS

┌──────────────────────────────────┬──────────────────────────────┬───────────────────────────────────────────────────────────┬───────────────────┐
│ What │ Currently │ Managed By │ Nix Mechanism │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Keyboard shortcuts (system-wide) │ System Preferences │ nix-darwin │ Limited support │
│ │ │ system.defaults.NSGlobalDomain.NSUserKeyEquivalents │ │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Accessibility settings (reduce │ System Preferences │ nix-darwin system.defaults.universalaccess.\* │ Limited │
│ motion, etc.) │ │ │ │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Input sources / keyboard layouts │ System │ nix-darwin │ Limited │
│ │ │ system.defaults.NSGlobalDomain.AppleKeyboardUIMode │ │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Display scaling │ System Preferences │ Not nix-managed (hardware-dependent) │ Excluded │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Sound settings (output device, │ System Preferences │ Not nix-managed (runtime state) │ Excluded │
│ volume) │ │ │ │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Printer configuration │ System Preferences │ Not nix-managed │ Excluded │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Bluetooth pairings │ System Preferences │ Not nix-managed (hardware state) │ Excluded │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ iCloud / Apple ID │ System Preferences │ Not nix-managed (Apple account state) │ Excluded │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Screen Time / Focus modes │ System Preferences │ Not nix-managed │ Excluded │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Notification settings per-app │ System Preferences │ nix-darwin system.defaults.CustomUserPreferences │ Partial │
│ │ │ (limited) │ │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ File associations / default apps │ Launch Services │ nix-darwin system.defaults.LaunchServices │ Limited — duti │
│ │ │ │ can help │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Spotlight indexing │ System default │ nix-darwin system.defaults.CustomUserPreferences │ Very limited │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Time Machine │ TimeMachineEditor modifies │ Not nix-managed (requires disk/backup destination) │ Excluded │
│ │ schedule │ │ │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Power management / sleep │ System Preferences │ nix-darwin power module (limited on macOS) │ Partial │
│ settings │ │ │ │
├──────────────────────────────────┼──────────────────────────────┼───────────────────────────────────────────────────────────┼───────────────────┤
│ Wallpaper │ System Preferences │ Not nix-managed │ Excluded │
└──────────────────────────────────┴──────────────────────────────┴───────────────────────────────────────────────────────────┴───────────────────┘

---

WHAT CANNOT BE DECLARATIVELY MANAGED

These are the hard boundaries:

1.  Apple ID / iCloud state — account login, sync settings
2.  FileVault initial setup — requires recovery key ceremony
3.  Xcode license acceptance — interactive sudo xcodebuild -license
4.  Bluetooth pairings — hardware state
5.  WiFi passwords — Keychain
6.  Printer drivers & config — hardware-dependent
7.  Display arrangement / scaling — hardware-dependent
8.  App-internal state (1Password vaults, Obsidian vault content, browser bookmarks/extensions beyond install)
9.  macOS Login Items registered via SMAppService (modern apps) — partially manageable
10. System extensions (Little Snitch network extension) — require user approval in System Settings
11. Accessibility permissions (TCC database) — require manual GUI approval
12. Full Disk Access / Screen Recording permissions — TCC, manual

---

ARCHITECTURE SUMMARY

flake.nix ← Single entry point
├── inputs: nixpkgs, nix-darwin, home-manager, sops-nix
│
├── darwinConfigurations."AVA" ← nix-darwin system config
│ ├── system.defaults._ ← All macOS defaults (Dock, Finder, Trackpad, etc.)
│ ├── networking._ ← Hostname, DNS, /etc/hosts
│ ├── security.pam._ ← Touch ID sudo
│ ├── environment.systemPackages ← CLI tools available system-wide
│ ├── fonts.packages ← System fonts
│ ├── launchd.daemons ← System-level daemons
│ ├── homebrew._ ← Declarative Homebrew (casks, MAS apps)
│ ├── nix._ ← Nix daemon config, GC, caches
│ ├── services._ ← System services
│ │
│ └── home-manager.users.CASE ← Embedded Home Manager config
│ ├── programs.zsh ← Shell (replaces .zshrc, oh-my-zsh)
│ ├── programs.git ← Git config (replaces .gitconfig)
│ ├── programs.ssh ← SSH config
│ ├── programs.gpg ← GPG config
│ ├── programs.tmux ← Tmux config
│ ├── programs.neovim ← Neovim config
│ ├── programs.alacritty ← Alacritty config
│ ├── programs.direnv ← direnv + nix-direnv
│ ├── programs.gh ← GitHub CLI
│ ├── programs.bat ← bat config
│ ├── programs.fzf ← fzf config
│ ├── programs.lazygit ← lazygit config
│ ├── home.packages ← User-level CLI tools
│ ├── home.file ← Arbitrary dotfiles (ghostty, zed, etc.)
│ ├── xdg.configFile ← ~/.config/\* files
│ ├── home.sessionVariables ← Environment variables
│ ├── launchd.agents ← User-level launch agents
│ └── home.activation ← Post-activation scripts
│
└── devShells ← Per-project development environments
└── (defined in each project's own flake.nix)

One command to rule them all: darwin-rebuild switch --flake . reads this entire tree and converges your machine to the declared state. Packages
installed, configs written, defaults set, services running, Homebrew synced — all atomically.

Phase 0: Human-only (before anything runs)

1. Apple ID login — you said you'd do this
2. FileVault enable — you said you'd do this
3. Xcode CLT install — xcode-select --install (GUI prompt, requires click)
4. Xcode license accept — sudo xcodebuild -license accept (if full Xcode needed)

Phase 1: Bootstrap script (automated)

This is where tooling helps. A single bootstrap.sh that:

1. Install Nix (deterministic-nix installer or official)
2. Clone your config repo
3. Run `darwin-rebuild switch --flake .` (installs EVERYTHING)

This is fully scriptable. One curl-pipe-bash to kick it off.

Phase 2: TCC / Permissions (human required, but tooling can guide)

This is the annoying part. macOS requires manual GUI clicks for these. But we can write a post-activation script that:

- Detects which apps need which permissions
- Opens the exact System Settings pane for each
- Prints a checklist

Here's what you'd need to grant:

┌─────────────────────────┬──────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────┐
│ Permission │ Apps That Need It │ Can We Automate? │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Accessibility │ Rectangle, Bartender, Alfred, Raycast, Shortery, │ No — click per app │
│ │ BetterDisplay │ │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Full Disk Access │ Terminal/Ghostty (for nix), Backblaze, Malwarebytes, Hazel │ No — click per app │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Screen Recording │ BetterDisplay, iStat Menus, CleanShot/Xnapper │ No — click per app │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Input Monitoring │ Karabiner (if used), Alfred, Raycast │ No — click per app │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Notifications │ Most apps — but they prompt on first launch │ Semi — just launch each app once │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Files & Folders │ Various apps on first access │ Semi — prompt-driven │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ System Extensions │ Little Snitch (network extension), GlobalProtect │ No — requires reboot │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Login Items │ Bartender, Raycast, Rectangle, iStat, Backblaze, Dropbox, │ Partially via launchd; modern SMAppService ones need │
│ │ etc. │ GUI │
├─────────────────────────┼──────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
│ Automation │ Alfred, Shortcuts, Shortery │ No — prompt on first use │
│ (AppleScript) │ │ │
└─────────────────────────┴──────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────┘

What we CAN build: A post-install script like:

#!/bin/bash
echo "Opening Security & Privacy settings..."
echo "Grant Accessibility to these apps:"
echo " - Rectangle, Raycast, Alfred, Bartender, Shortery, BetterDisplay"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
read -p "Press enter when done..."

echo "Grant Full Disk Access to these apps:"
echo " - Ghostty, Backblaze, Malwarebytes, Hazel"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
read -p "Press enter when done..."

echo "Grant Screen Recording to these apps:"
echo " - BetterDisplay, iStat Menus, Xnapper"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
read -p "Press enter when done..."

# ... etc for each category

There's also MDM profiles — if you enroll the Mac in a personal MDM (like MicroMDM or Mosyle), you can push TCC profiles that pre-approve apps without
clicking. That's how enterprises do it. Overkill for one machine, but it exists.

Phase 3: App-specific login (human, unavoidable)

- 1Password (then everything else flows from it)
- iCloud (already done in Phase 0)
- Dropbox, Backblaze, Slack, Discord, etc.

Tooling idea: A open -a script that launches every app that needs login, one at a time, so you can sign in assembly-line style.

Summary: the bootstrap is 3 commands + ~15 minutes of clicking

# Phase 0

xcode-select --install

# Phase 1 (one command)

curl -L https://your-repo/bootstrap.sh | bash

# This installs nix, clones config, runs darwin-rebuild switch

# Phase 2 (guided wizard)

~/.config/nix/scripts/grant-permissions.sh

# Phase 3 (open apps that need login)

~/.config/nix/scripts/login-apps.sh

---

2. Do You Strictly Need Home Manager?

Short answer: No, but you'd be writing a lot of it yourself.

Here's the precise split of what each tool provides:

What nix-darwin gives you (no home-manager needed)

┌───────────────────────────────────┬──────────────────────────────────────────────┐
│ Capability │ nix-darwin mechanism │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Install CLI tools system-wide │ environment.systemPackages │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Install GUI apps via Homebrew │ homebrew.casks, homebrew.masApps │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ All macOS defaults write settings │ system.defaults._ │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Hostname, DNS, /etc/hosts │ networking._ │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ System fonts │ fonts.packages │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Touch ID for sudo │ security.pam.services.sudo_local.touchIdAuth │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Firewall │ system.defaults.alf._ │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Launch daemons (system-level) │ launchd.daemons │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Launch agents (user-level) │ launchd.agents │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Nix daemon config, GC, caches │ nix._ │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ System-wide env vars │ environment.variables │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ System-wide shell init │ environment.interactiveShellInit │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ Enable zsh (basic) │ programs.zsh.enable │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│ /etc/\* files │ Various modules │
└───────────────────────────────────┴──────────────────────────────────────────────┘

What home-manager adds that nix-darwin cannot do

┌──────────────────────────────────────────────────┬──────────────────────────────────────────┬───────────────────────────────────────────────────┐
│ Capability │ Home Manager mechanism │ nix-darwin equivalent? │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ Dotfile management (arbitrary files in ~) │ home.file, xdg.configFile │ None │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ Per-user session variables │ home.sessionVariables │ environment.variables exists but is system-wide │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ Rich program modules with config generation: │ │ │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.git (generates .gitconfig from │ userName, signing, aliases, difftastic, │ None — you'd write .gitconfig yourself │
│ attrset) │ ignores, extraConfig │ │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.zsh (generates .zshrc) │ oh-my-zsh, shellAliases, initExtra, │ nix-darwin has basic programs.zsh.enable but no │
│ │ plugins, completionInit │ aliases, initExtra, oh-my-zsh │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.ssh (generates ~/.ssh/config) │ matchBlocks with typed options │ None │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.tmux (generates .tmux.conf) │ plugins, extraConfig, shell, terminal │ None │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.neovim (manages plugins + config) │ plugin list, extraLuaConfig, coc │ None │
│ │ settings │ │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.alacritty (generates TOML) │ settings attrset │ None │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.direnv + nix-direnv │ enables auto-activation of devShells │ None │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.gpg │ settings, homedir │ None │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ → programs.bat, programs.fzf, programs.htop, │ Each generates its config file │ None │
│ programs.lazygit, programs.gh, ... │ │ │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ User-level activation scripts │ home.activation │ None │
├──────────────────────────────────────────────────┼──────────────────────────────────────────┼───────────────────────────────────────────────────┤
│ Cross-platform portability │ Same config works on NixOS/Linux │ nix-darwin is macOS-only │
└──────────────────────────────────────────────────┴──────────────────────────────────────────┴───────────────────────────────────────────────────┘
