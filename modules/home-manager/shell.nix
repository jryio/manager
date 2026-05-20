{ config, lib, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  fzfTabPackage =
    if builtins.hasAttr "zsh-fzf-tab" pkgs then
      pkgs."zsh-fzf-tab"
    else if builtins.hasAttr "fzf-tab" pkgs then
      pkgs."fzf-tab"
    else
      throw "No fzf-tab package found in pkgs";

  # mkOrder layout (HM stages in parens, ours unparen'd):
  #   510  typeset/cdpath          [HM]
  #   520  NIX_PROFILES fpath      [HM]
  #   530  defaultKeymap bindkey   [HM]
  #   540  localVariables          [HM]
  #   550  completion-styles.zsh   <- fzf-tab zstyles, before compinit
  #   560  plugin path/fpath       [HM, fzf-tab]
  #   570  compinit                [HM]
  #   700  autosuggestion source   [HM]
  #   720  zsh-options.zsh         <- setopts, keybinds, take/mkcd
  #   750  git-aliases.zsh         <- vendored OMZ git plugin + helpers
  #   900  plugin sourcing         [HM, fzf-tab]
  #   910  history setopts         [HM]
  #   950  user setOptions         [HM, unused]
  #  1000  init.zsh                <- SSH agent, BUN, NVM, GPG, functions
  #         starship init zsh      [HM, default 1000]
  #  1100  shellAliases / global   [HM]
  #  1200  syntaxHighlighting      [HM]
  zshInitContent = lib.mkMerge [
    (lib.mkOrder 550 (builtins.readFile ./shell/completion-styles.zsh))
    (lib.mkOrder 720 (builtins.readFile ./shell/zsh-options.zsh))
    (lib.mkOrder 750 (builtins.readFile ./shell/git-aliases.zsh))
    (lib.mkOrder 1000 (builtins.readFile ./shell/init.zsh))
  ];
in
{
  programs.zsh = {
    enable = true;
    dotDir = homeDir;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";

    envExtra = builtins.readFile ./shell/env.zsh;
    profileExtra = builtins.readFile ./shell/profile.zsh;
    initContent = zshInitContent;

    history = {
      size = 50000;
      save = 50000;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      n = "lvim";
      irb = "irb --simple-prompt";
      lg = "lazygit";
      kk = "clear";
      z = "zed";
      htop = "btm";
      golint = "golangci-lint";
      ai = "ollama run";
      bgrep = "/usr/bin/grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}";
      gc = "git commit -v -S";
      gcob = "gco -b";
      gd = "git difftool";
      gdc = "git difftool --cached";
      grba = "LEFTHOOK=0 git rebase --abort";
      grbc = "LEFTHOOK=0 git rebase --continue";
      grbsign = "LEFTHOOK=0 git rebase --exec 'git commit --amend --no-edit -n -S' --update-refs -i";
      ggpush = "git push -u origin $(git_current_branch)";
      grs = "git restore --staged";
      jjgi = "jj git init --colocate";
      jjst = "jj st";
      jjl = "jj log";
      jjn = "jj new";
      tx = "nocorrect tmux attach-session 2>/dev/null || tmux new-session";
      jqs = "jq -r '[path(..)|map(if type==\"number\" then \"[]\" else tostring end)|join(\".\")|split(\".[]\")|join(\"[]\")]|unique|map(\".\" + .)|.[]'";
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      cc = "claude --dangerously-skip-permissions";
      herder = "herdr";
      drs = "sudo darwin-rebuild switch --flake path:/Users/CASE/manager#AVA";
    };

    shellGlobalAliases = {
      "..." = "../..";
      "...." = "../../..";
      "....." = "../../../..";
    };

    plugins = [
      {
        name = "fzf-tab";
        src = fzfTabPackage;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;

      format = lib.concatStrings [
        "$username" "$hostname" "$directory"
        "$git_branch" "$git_state" "$git_status"
        "$fill" "$cmd_duration"
        "$line_break" "$character"
      ];

      right_format = lib.concatStrings [
        "$status" "$jobs" "$direnv"
        "$nodejs" "$bun" "$golang" "$rust" "$python" "$haskell"
      ];

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❮](bold red)";
        vimcmd_symbol = "[V](bold green)";
        vimcmd_replace_symbol = "[▶](bold magenta)";
      };

      username = {
        show_always = false;
        format = "[$user]($style)@";
        style_user = "yellow";
        style_root = "bold red";
      };

      hostname = {
        ssh_only = true;
        format = "[$hostname]($style) ";
        style = "yellow";
      };

      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 1;
        repo_root_style = "bold blue";
        style = "blue";
        read_only = " ";
      };

      fill = {
        symbol = "─";
        style = "bright-black";
      };

      git_branch = {
        symbol = " ";
        format = "[$symbol$branch]($style) ";
        style = "magenta";
      };

      git_status = {
        format = "([\\[$ahead_behind$stashed$staged$modified$untracked$conflicted\\]]($style) )";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇡\${ahead_count}⇣\${behind_count}";
        stashed = "*\${count}";
        staged = "+\${count}";
        modified = "!\${count}";
        untracked = "?\${count}";
        conflicted = "~\${count}";
        style = "yellow";
      };

      git_state.format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";

      cmd_duration = {
        min_time = 2000;
        format = "[ took $duration]($style) ";
        style = "yellow";
      };

      jobs = {
        symbol = "⚙ ";
        format = "[$symbol$number]($style) ";
        style = "blue";
        number_threshold = 1;
      };

      status = {
        disabled = false;
        symbol = "✘";
        format = "[$symbol $common_meaning$signal_name$maybe_int]($style) ";
        style = "red";
        pipestatus = true;
      };

      direnv = {
        disabled = false;
        format = "[direnv:$loaded/$allowed]($style) ";
      };

      nodejs  = { format = "[$symbol($version )]($style)"; symbol = " "; style = "green"; };
      bun     = { format = "[$symbol($version )]($style)"; symbol = "🍞 "; style = "yellow"; };
      golang  = { format = "[$symbol($version )]($style)"; symbol = " "; style = "cyan"; };
      rust    = { format = "[$symbol($version )]($style)"; symbol = " "; style = "red"; };
      python  = {
        format = "[\${symbol}\${pyenv_prefix}(\${version} )(\\($virtualenv\\) )]($style)";
        symbol = " ";
        style = "yellow";
      };
      haskell = { format = "[$symbol($version )]($style)"; symbol = " "; style = "magenta"; };

      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
      kubernetes.disabled = true;
      docker_context.disabled = true;
      package.disabled = true;
      conda.disabled = true;
      ruby.disabled = true;
      java.disabled = true;
      php.disabled = true;
      scala.disabled = true;
      swift.disabled = true;
      dotnet.disabled = true;
      terraform.disabled = true;
      memory_usage.disabled = true;
      time.disabled = true;
    };
  };

  home.sessionPath = [ "${homeDir}/.local/bin" ];

  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "rg --files --hidden --smart-case --follow --glob '!.git/*'";
  };
}
