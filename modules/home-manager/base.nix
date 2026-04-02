{ host, ... }:

{
  imports = [
    ./packages.nix
  ];

  home.username = host.username;
  home.homeDirectory = host.homeDirectory;
  home.stateVersion = host.homeStateVersion or "25.11";

  programs.home-manager.enable = true;
}
