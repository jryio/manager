{ host, ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./fonts.nix
    ./gpg.nix
    ./ssh.nix
    ./git.nix
    ./tmux.nix
    ./ghostty.nix
    ./herdr.nix
    ./github.nix
    ./jujutsu.nix
    ./television.nix
    ./monitoring.nix
    ./vale.nix
    ./editors.nix
    ./zed.nix
    ./ai-tools.nix
  ];

  home.username = host.username;
  home.homeDirectory = host.homeDirectory;
  home.stateVersion = host.homeStateVersion or "25.11";

  programs.home-manager.enable = true;
}
