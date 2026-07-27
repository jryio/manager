{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    global.brewfile = false;

    taps = [
      "charmbracelet/tap"
      "docker/tap"
      "heroku/brew"
      "homebrew/aliases"
      "homebrew/bundle"
      "homebrew/cask-versions"
      "homebrew/services"
      "neovim/neovim"
      "oven-sh/bun"
      "rbenv/tap"
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
      "alacritty"
      "codex"
      "gcloud-cli"
      "ghostty"
      "gitify"
      "gpg-suite"
      "macfuse"
      "markedit"
      "miniconda"
      "ngrok"
      "powershell"
      "timemachineeditor"
      "vagrant"
      "wireshark-app"
      "xquartz"
    ];

    masApps = {
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
