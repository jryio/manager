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

  signing.gpgKey = "715CED2327899E28";

  # Per-identity gitego data. Keys match the names referenced by the gitego
  # auto_rules table, the per-profile gitconfig fragments, and the SSH host
  # aliases (github-jry/github-inf/...). See .ai/inventory/gitego-config.yaml.
  identities = {
    jry = {
      name = user.fullName;
      email = "git@jry.io";
      sshKey = "${user.home}/.ssh/id_rsa";
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
      autoRules = [ "${user.home}/code/professional/infinitemusic/" ];
    };
    tdna = {
      name = user.fullName;
      email = "jacob.young@tech-dna.net";
      sshKey = "${user.home}/.ssh/tdna";
      autoRules = [ "${user.home}/code/professional/tdna/" ];
    };
    zigg = {
      name = user.fullName;
      email = "jacob.young@ziggiz.ai";
      sshKey = "${user.home}/.ssh/zigguratum";
      autoRules = [ "${user.home}/code/professional/zigg/" ];
    };
    keybase = {
      name = user.fullName;
      email = "jacob@keyba.se";
      sshKey = null; # keybase profile is HTTPS-only per gitego-inventory.md
      autoRules = [ "${user.home}/code/professional/keybase/" ];
    };
  };

  # The active gitego profile becomes the global git identity.
  activeIdentity = "jry";

  paths = {
    screenshots = "${user.home}/Dropbox/media/screenshots";
  };
}
