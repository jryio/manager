{ lib, host, ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    global.brewfile = false;

    # homebrew/{aliases,bundle,cask-versions,services} were removed 2026-07:
    # deprecated upstream and now empty (functionality migrated into brew
    # core), so tapping them fails on a fresh machine. They remain tapped
    # locally on AVA per cleanup = "none"; that is harmless.
    taps = [
      "charmbracelet/tap"
      "docker/tap"
      "heroku/brew"
      "neovim/neovim"
      "oven-sh/bun"
      "rbenv/tap"
      "steipete/tap"
      "steveyegge/beads"
      "stripe/stripe-cli"
    ];

    brews = [
      "agent-browser"
      "avro-tools"
      "awk"
      "azure-cli"
      "bat"
      "black"
      "blueutil"
      # btop: Nix-managed via programs.btop in modules/home-manager/monitoring.nix (D5)
      "caddy"
      "cask"
      "ccusage"
      "charmbracelet/tap/crush"
      "charmbracelet/tap/freeze"
      "cloc"
      "cmake"
      "curl"
      "difftastic"
      "doctl"
      "dos2unix"
      "edencommon"
      "eksctl"
      "elixir"
      "exercism"
      "exiftool"
      "figlet"
      "fluent-bit"
      "flyctl"
      "fontforge"
      "fzf"
      "gawk"
      "gemini-cli"
      # gh: Nix-managed via programs.gh in modules/home-manager/github.nix (D5)
      # git: Nix-managed via programs.git in modules/home-manager/git.nix (D5)
      "git-who"
      "gnupg"
      "gnuplot"
      "go-task"
      "gobject-introspection"
      "golangci-lint"
      "goreleaser"
      "gpsbabel"
      "graphviz"
      "grep"
      "grpcurl"
      "harper"
      "helix"
      "helm"
      "heroku"
      "hf"
      # htop: Nix-managed via programs.htop in modules/home-manager/monitoring.nix (D5)
      "hugo"
      "hyperfine"
      "imagemagick"
      "imagemagick@6"
      "iperf3"
      # jj: Nix-managed via programs.jujutsu in modules/home-manager/jujutsu.nix (D5)
      "jq"
      "lazygit"
      "libass"
      "libffi"
      "libfido2"
      "libmagic"
      "librist"
      "markdownlint-cli"
      "mas" # declared so brew bundle's masApps calls use a current CLI (bundle now invokes `mas get`)
      "mintoolkit"
      "mise"
      "mosh"
      "mysql"
      "neovim"
      "nmap"
      "nushell"
      "oha"
      "opentofu"
      "openvino"
      "oven-sh/bun/bun"
      "pinentry-mac"
      "pipx"
      "portaudio"
      "postgresql@14"
      "powershell"
      "pre-commit"
      "prek"
      "pstree"
      "pyenv"
      "python@3.9"
      "rbenv"
      "resvg"
      "sevenzip"
      "shared-mime-info"
      "srt"
      "sshpass"
      "steveyegge/beads/bd"
      "stripe/stripe-cli/stripe"
      # television: Nix-managed via programs.television in modules/home-manager/television.nix (D5)
      "tailscale"
      "tesseract"
      "tig"
      # tmux: Nix-managed via programs.tmux in modules/home-manager/tmux.nix (D5)
      "tree"
      "trivy"
      "uv"
      # vale: Nix-managed via home.packages in modules/home-manager/vale.nix (D5)
      "vegeta"
      "vhs"
      "vim"
      "wget"
      "yarn"
      "yt-dlp"
      "zeromq"
      "zola"
    ];

    casks = [
      "1password-cli"
      "alacritty" # deprecated upstream (Gatekeeper), disable date 2026-09-01 -- decide before then (bd)
      # AI tools: binaries/apps only. Their local state (~/.claude, ~/.claude.json,
      # ~/.codex, ~/Library/Application Support/Claude|Codex) is intentionally
      # unmanaged -- these files change too often to declare.
      # (claude-code CLI is NOT a cask: the native installer self-updates, the
      # cask does not -- see modules/home-manager/ai-tools.nix)
      "claude" # Claude Desktop (auto_updates: brew installs once, app updates itself)
      "codex"
      "codex-app" # Codex desktop (deprecated upstream 2026-07; Homebrew suggests `chatgpt` cask as replacement)
      "gcloud-cli"
      "ghostty"
      "gitify"
      "gpg-suite"
      "macfuse"
      "markedit"
      "miniconda"
      "ngrok"
      # powershell cask removed 2026-07: deleted upstream (Gatekeeper); the
      # `powershell` FORMULA above still provides pwsh. AVA's old cask install
      # stays per cleanup = "none".
      "steipete/tap/codexbar" # menu-bar usage meter for Codex/Claude CLI sessions
      "timemachineeditor"
      "vagrant"
      "wireshark-app"
      "xquartz"
    ]
    # Daily-driver GUI apps: everything from the dock seed and the permissions
    # walkthrough that has a cask (names verified against the live cask index
    # 2026-07-28; mapping from .ai/inventory/applications-manual.txt). AVA
    # predates these as manual installs and sets `guiAppCasks = false` in its
    # host file until they are adopted (`brew install --cask --adopt/--force`);
    # fresh machines get them all. No cask exists for: Conductor, Mercury,
    # ZMK Studio, Geotag Photos Pro — those stay manual.
    ++ lib.optionals (host.guiAppCasks or true) [
      "1password"
      "backblaze"
      "bartender"
      "betterdisplay"
      "cap"
      "cleanshot"
      "daisydisk"
      "discord"
      "docker-desktop"
      "dropbox"
      "fantastical"
      "firefox"
      "google-chrome"
      "hazel"
      "hey"
      "istat-menus"
      "logi-options-plus"
      "macwhisper"
      "monitorcontrol"
      "notion"
      "notion-calendar"
      "raycast"
      "rectangle"
      "rocket"
      "signal"
      "spotify"
      "tableplus"
      "zed"
      "zulip"
    ];

    # MAS installs need an interactive App Store sign-in and can hang or abort
    # the whole activation on a fresh machine (mas may block on auth). Hosts
    # can defer them with `masApps = false;` in hosts/<name>/default.nix and
    # re-enable (set true or remove the key) once sign-in is stable.
    masApps = lib.optionalAttrs (host.masApps or true) {
      "1Blocker" = 1365531024;
      "1Password for Safari" = 1569813296;
      "Adobe Lightroom" = 1451544217;
      "Amphetamine" = 937984704;
      "Anybox" = 1593408455;
      "Backgroundifier" = 1040333206;
      "Calca" = 635758264;
      "Cardhop" = 1290358394;
      "Color Picker" = 641027709;
      "Craft" = 1487937127;
      "Crypto Pro" = 980888073;
      "Dark Noise" = 1465439395;
      "Day One" = 1055511498;
      "Deliveries" = 924726344;
      "Figr" = 1630860606;
      "FitFileExplorer" = 1244431640;
      "Flighty" = 1358823008;
      "Focused Work" = 1523968394;
      "Foodnoms" = 1479461686;
      "GarageBand" = 682658836;
      "GeoTagster" = 1180435565;
      "Habits" = 1514915737;
      "Health Auto Export" = 1115567069;
      "iA Writer" = 775737590;
      "iMovie" = 408981434;
      "Instapaper Save" = 1481302432;
      "iStat Mini" = 927292435;
      "Keynote" = 409183694;
      "Microsoft Excel" = 462058435;
      "Microsoft Word" = 462054704;
      "Noir" = 1592917505;
      "Pages" = 409201541;
      "Parcel Classic" = 639968404;
      "PiPifier" = 1160374471;
      "Portal" = 1436994560;
      "Redacted" = 984968384;
      "Shortery" = 1594183810;
      "Slack" = 803453959;
      "Soulver 3" = 1508732804;
      "Things3" = 904280696;
      "TickTick" = 966085870;
      "Timery" = 1425368544;
      "Vimari" = 1480933944;
      "Xcode" = 497799835;
    };
  };
}
