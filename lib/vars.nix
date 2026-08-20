# Cross-module constants. Single source of truth for identity, signing, and
# user-scoped paths. Threaded through every nix-darwin and Home Manager module
# via specialArgs/extraSpecialArgs as `vars` (see flake.nix).
#
# Host-specific values (username, homeDirectory, hostName, ...) stay in
# hosts/<host>/default.nix and feed in here through the `host` argument so
# there is no duplication.

{ host }:

let
  user = {
    fullName = "Jacob Young";
    primary = host.username;
    home = host.homeDirectory;
  };
in
rec {
  inherit user;

  signing = {
    # Global default: the only [SC]-capable secret key in ~/.gnupg (D10).
    # Identities that set `signing.sshKey` below override this inside their
    # auto_rule path trees.
    gpgKey = "715CED2327899E28";

    # 1Password's git-compatible SSH signer. Ships with the macOS app.
    opSshSign = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

    allowedSignersFile = "${user.home}/.ssh/allowed_signers";
  };

  # Per-identity gitego data. Keys match the names referenced by the gitego
  # auto_rules table, the per-profile gitconfig fragments, and the SSH host
  # aliases (github-jry/github-tdna/...). See .ai/inventory/gitego-config.yaml
  # for the historical five-identity snapshot; inf and zigg were retired
  # 2026-07-29 (no longer needed).
  #
  # `sshKey` — path gitego records in config.yaml (informational; auth routes
  #            through the 1Password agent). null when no on-disk key exists.
  # `sshAuthKeyFile` — public key passed to SSH with IdentitiesOnly so the
  #                     agent offers the profile's intended identity.
  # `signingKey` — literal ED25519 public key to sign commits with via
  #             op-ssh-sign, scoped to this identity's autoRules. null falls
  #             back to the global GPG key. Every non-null value here MUST be
  #             surfaced by the 1Password SSH agent (`ssh-add -l`) or signing
  #             fails at commit time — the agent only exposes the vaults and
  #             items allowed by ~/.config/1Password/ssh/agent.toml.
  identities = {
    jry = {
      name = user.fullName;
      email = "git@jry.io";
      sshKey = "${user.home}/.ssh/id_rsa";
      sshAuthKeyFile = "${user.home}/.ssh/id_rsa";
      # "Github SSH" in the 1Password Personal vault.
      # SHA256:OYWAVNkofwChH+T6s4MJw/fLr7bZq/yaW4m4jzk/SQo
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA15SwxcYtsXvWLmqWK4L7p9yXQClXWLZ+lGiZvTeIK7";
      autoRules = [
        "${user.home}/code/personal/statis/"
        "${user.home}/code/personal/jryio/"
        "${user.home}/code/personal/adr/"
      ];
    };
    tdna = {
      name = user.fullName;
      email = "jacob.young@tech-dna.net";
      sshKey = "${user.home}/.ssh/tdna";
      sshAuthKeyFile = "${user.home}/.ssh/tdna.pub";
      # "Tech DNA SSH Key" in 1Password.
      # SHA256:DXfyLK1dbLy3CroikJl44TuOec4JNGjVCzC1mODzb40
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIcLG93apm3T5H5lr2EVnUb9fxwHGC/UZd+N4rSVmCg";
      autoRules = [ "${user.home}/code/professional/tdna/" ];
    };
    keybase = {
      name = user.fullName;
      email = "jacob@keyba.se";
      sshKey = null; # keybase profile is HTTPS-only per gitego-inventory.md
      signingKey = null; # no SSH key exists for this identity; signs with GPG
      sshAuthKeyFile = null;
      autoRules = [ "${user.home}/code/professional/keybase/" ];
    };
    cloudx = {
      name = user.fullName;
      email = "jacob@cloudx.io";
      # Key lives only in the 1Password CloudX vault and routes through the
      # agent (D18); no on-disk path exists, so gitego records none.
      sshKey = null;
      # "CloudX SSH Key" in the 1Password CloudX vault.
      sshAuthKeyFile = null;
      # SHA256:/2XMZawY/x6Q/wF1RxHlrd/8rZsCUNzpoMD7+86Yiug
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE8xbPkFj5CUNx0BmaFbADC8t4XT/3EQ+aBX0j60u5Y7";
      autoRules = [ "${user.home}/code/professional/cloudx/" ];
    };
  };

  # The active gitego profile becomes the global git identity.
  activeIdentity = "jry";

  paths = {
    screenshots = "${user.home}/Dropbox/media/screenshots";
  };
}
