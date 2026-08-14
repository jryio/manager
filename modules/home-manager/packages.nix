{ pkgs, ... }:

{
  home.packages = [
    pkgs.gum
    pkgs.zig_0_15
  ];
}
