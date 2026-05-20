{ config, lib, pkgs, vars, ... }:

let
  jry = vars.identities.${vars.activeIdentity};
in
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = jry.name;
        email = jry.email;
      };

      signing = {
        # GPG owns commit/tag signing per D10.
        backend = "gpg";
        key = vars.signing.gpgKey;
        sign-all = true;
      };

      ui = {
        default-command = "log";
        diff-editor = ":builtin";
      };
    };
  };
}
