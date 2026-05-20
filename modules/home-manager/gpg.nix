{ config, lib, pkgs, vars, ... }:

# Signing-only GPG configuration per MIGRATION.md D10.
#
# - gpg-agent runs WITHOUT SSH support (enableSshSupport = false). 1Password
#   is the sole SSH agent; see modules/home-manager/ssh.nix.
# - pinentry-mac stays on the Homebrew bridge per D5, so we do not vendor a
#   pinentry from nixpkgs. The agent locates it via pinentry-program in the
#   generated gpg-agent.conf.
# - The active secret signing key on AVA is 715CED2327899E28 (long-id);
#   full fingerprint 2848EFB300F361FD6D770DC0715CED2327899E28. The stale
#   default-key (099A18D55F20E2E810EE960EDFAED45206F8A9FA) in the legacy
#   ~/.gnupg/gpg.conf is intentionally dropped here per gpg-keys.txt
#   anomaly 1.
# - auto-key-locate aligns with ~/.gnupg/dirmngr.conf (hkps://keys.openpgp.org)
#   instead of the deprecated sks-keyservers pool from anomaly 2.
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;

    defaultCacheTtl = 600;
    maxCacheTtl = 7200;

    # pinentry comes from the Homebrew bridge (cask `pinentry-mac`) per D5.
    # We do not let Home Manager wire a nixpkgs pinentry; setting the package
    # to null prevents an unwanted default and lets the explicit
    # pinentry-program below take over.
    pinentry.package = null;

    extraConfig = ''
      pinentry-program /opt/homebrew/bin/pinentry-mac
    '';
  };

  programs.gpg = {
    enable = true;

    settings = {
      default-key = vars.signing.gpgKey;
      "auto-key-locate" = "keyserver hkps://keys.openpgp.org";
    };

    # Public-key import stays manual. The keyring at ~/.gnupg/pubring.kbx
    # carries decades of social-graph keys (see gpg-keys.txt); we do not
    # re-import them declaratively.
    publicKeys = [ ];
  };
}
