{ host, ... }:

{
  programs.zsh = {
    enable = true;
    # Home Manager adds fzf-tab to fpath before its compinit call.
    # Keep system completion files; skip the earlier global initialization.
    enableGlobalCompInit = false;
  };

  users.users.${host.username}.shell = "/bin/zsh";
}
