{ host, hostName, lib, ... }:

{
  imports = [
    ./packages.nix
    ./homebrew.nix
    ./shell.nix
    ./hosts.nix
    ./defaults.nix
    ./launchd.nix
  ];

  determinateNix.enable = true;

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  networking.hostName = lib.mkDefault (host.hostName or hostName);
  networking.localHostName = lib.mkDefault (host.localHostName or (host.hostName or hostName));
  networking.computerName = lib.mkDefault (host.computerName or (host.localHostName or hostName));

  system.primaryUser = host.username;
  system.stateVersion = host.stateVersion or 6;

  users.users.${host.username}.home = host.homeDirectory;
}
