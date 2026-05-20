{ config, lib, pkgs, ... }:

# SSH client configuration per MIGRATION.md D18 / ADR 10.
#
# - The 1Password macOS app exposes its SSH agent at a Group-Container path
#   under $HOME. We build the path from config.home.homeDirectory rather than
#   hardcoding /Users/CASE so the module reproduces under testaccount too.
# - All identity routing happens through the 1Password agent. We deliberately
#   do NOT set IdentityFile anywhere — the agent surfaces the right key by
#   fingerprint per the gitego identities (jry/inf/tdna/zigg/keybase, see
#   gitego-inventory.md).
# - Host aliases (github-jry, github-inf, github-tdna, github-zigg,
#   github-keybase) provide a stable per-identity name surface that the
#   gitego per-profile fragments and any operator URL rewrites can target.
# - Private keys on disk are out of scope: D18 retires every private key into
#   the 1Password vault; only ~/.ssh/allowed_signers remains operator-owned
#   on disk (see TODO at the bottom).
let
  onePasswordSocket =
    "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

  # IdentityAgent paths with spaces must be shell-quoted inside ssh_config.
  identityAgentValue = ''"${onePasswordSocket}"'';

  # All five gitego identities share the same agent. The fingerprint-based
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
      "github-inf" = githubMatchBlock;
      "github-tdna" = githubMatchBlock;
      "github-zigg" = githubMatchBlock;
      "github-keybase" = githubMatchBlock;
    };
  };

  # TODO(manager-4.13/4.15): the allowed_signers file maps the four ED25519
  # public keys in the 1Password vault to git identities. It is currently
  # operator-managed at ~/.ssh/allowed_signers (297 bytes, see
  # ssh-keys-inventory.md). Once Topic 04 decides whether to regenerate it
  # from the gitego identity table, replace the manual file with:
  #   home.file.".ssh/allowed_signers".source = ./assets/ssh/allowed_signers;
  # No private/public key bytes are vendored from this module.
}
