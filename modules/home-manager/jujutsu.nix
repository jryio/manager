{ config, lib, pkgs, ... }:

{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Jacob Young";
        # Matches the gitego "jry" identity (.ai/inventory/gitego-config.yaml).
        email = "git@jry.io";
      };

      signing = {
        # GPG owns commit/tag signing per D10.
        backend = "gpg";
        key = "715CED2327899E28";
        sign-all = true;
      };

      ui = {
        default-command = "log";
        diff-editor = ":builtin";
      };
    };
  };
}
