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
  # aliases (github-jry/github-inf/...). See .ai/inventory/gitego-config.yaml.
  #
  # `sshKey`  — path gitego records in config.yaml (informational; auth routes
  #             through the 1Password agent). null when no on-disk key exists.
  # `signingKey` — literal ED25519 public key to sign commits with via
  #             op-ssh-sign. null means fall back to the global GPG key.
  identities = {
    jry = {
      name = user.fullName;
      email = "git@jry.io";
      sshKey = "${user.home}/.ssh/id_rsa";
      signingKey = null;
      autoRules = [
        "${user.home}/code/personal/statis/"
        "${user.home}/code/personal/jryio/"
        "${user.home}/code/personal/adr/"
      ];
    };
    inf = {
      name = user.fullName;
      email = "git@sancho.studio";
      sshKey = "${user.home}/.ssh/infinite-music";
      signingKey = null;
      autoRules = [ "${user.home}/code/professional/infinitemusic/" ];
    };
    tdna = {
      name = user.fullName;
      email = "jacob.young@tech-dna.net";
      sshKey = "${user.home}/.ssh/tdna";
      signingKey = null;
      autoRules = [ "${user.home}/code/professional/tdna/" ];
    };
    zigg = {
      name = user.fullName;
      email = "jacob.young@ziggiz.ai";
      sshKey = "${user.home}/.ssh/zigguratum";
      signingKey = null;
      autoRules = [ "${user.home}/code/professional/zigg/" ];
    };
    keybase = {
      name = user.fullName;
      email = "jacob@keyba.se";
      sshKey = null; # keybase profile is HTTPS-only per gitego-inventory.md
      signingKey = null;
      autoRules = [ "${user.home}/code/professional/keybase/" ];
    };
    cloudx = {
      name = user.fullName;
      email = "jacob@cloudx.io";
      # Key lives only in the 1Password CloudX vault and routes through the
      # agent (D18); no on-disk path exists, so gitego records none.
      sshKey = null;
      # SSH-format commit signing via op-ssh-sign instead of the global GPG
      # key. Fingerprint SHA256:/2XMZawY/x6Q/wF1RxHlrd/8rZsCUNzpoMD7+86Yiug
      # ("CloudX SSH Key" in the 1Password agent).
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
