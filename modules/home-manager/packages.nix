{
  config,
  inputs,
  pkgs,
  ...
}:

let
  neovimPkgs = inputs.nixpkgs-neovim.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Home Manager's profile must precede Homebrew so the Nix-built Neovim is
  # selected even while `cleanup = "none"` retains Homebrew's old binary.
  home.sessionPath = [ "${config.home.profileDirectory}/bin" ];

  home.packages = [
    pkgs.gum
    neovimPkgs.neovim
    pkgs.zig_0_15
  ];
}
