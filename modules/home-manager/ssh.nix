{ config, lib, pkgs, ... }:

# SSH client configuration per MIGRATION.md D18.
#
# - The 1Password macOS app exposes its SSH agent at a Group-Container path
#   under $HOME. We build the path from config.home.homeDirectory rather than
#   hardcoding /Users/CASE so the module reproduces under testaccount too.
# - All identity routing happens through the 1Password agent. We deliberately
#   do NOT set IdentityFile anywhere — the agent surfaces the right key by
#   fingerprint per the gitego identities (jry/tdna/keybase/cloudx, see
#   gitego-inventory.md; inf and zigg were retired 2026-07-29).
# - Host aliases (github-jry, github-tdna, github-keybase, github-cloudx)
#   provide a stable per-identity name surface that the gitego per-profile
#   fragments and any operator URL rewrites can target.
# - Private keys on disk are out of scope: D18 retires every private key into
#   the 1Password vault; only ~/.ssh/allowed_signers remains operator-owned
#   on disk (see TODO at the bottom).
let
  onePasswordSocket =
    "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

  # IdentityAgent paths with spaces must be shell-quoted inside ssh_config.
  identityAgentValue = ''"${onePasswordSocket}"'';

  # All gitego identities share the same agent. The fingerprint-based
  # selection inside 1Password ensures the right key gets used per remote.
  githubMatchBlock = {
    hostname = "github.com";
    user = "git";
    extraOptions = {
      IdentityAgent = identityAgentValue;
    };
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        extraOptions = {
          IdentityAgent = identityAgentValue;
        };
      };

      "github-jry" = githubMatchBlock;
      "github-tdna" = githubMatchBlock;
      "github-keybase" = githubMatchBlock;
      "github-cloudx" = githubMatchBlock;
    };
  };

  # TODO: allowed_signers maps signing public keys to git identities
  # for *verification*. It is still operator-managed at ~/.ssh/allowed_signers
  # and now duplicates the `signingKey` values in lib/vars.nix, so it could be
  # generated from that table instead:
  #   home.file.".ssh/allowed_signers".text = ...
  # Deferred because the live file also carries a retired inf entry
  # (git@sancho.studio) that keeps historical inf-signed commits verifiable;
  # generating from vars.nix would drop it.
}
