{ config, lib, pkgs, ... }:

# Declarative git + gitego configuration per MIGRATION.md D25 / ADR 12.
#
# - The five gitego identities below (jry/inf/tdna/zigg/keybase) are taken
#   verbatim from .ai/inventory/gitego-config.yaml. Names, emails, and
#   ssh_key paths match the live ~/.gitego/config.yaml on AVA.
# - The active profile is `jry`; its [user] block becomes the global git
#   identity, which matches the live ~/.gitconfig.
# - GPG signing uses key 715CED2327899E28 per D10 (the only [SC]-capable
#   secret key in ~/.gnupg). Per-identity SSH-signing overrides for
#   inf/tdna/zigg/keybase live in the generated profile fragments and
#   continue to take precedence inside their auto_rule path trees.
# - includeIf rules are generated from the same identity table that feeds
#   the gitego YAML, so there is exactly one source of truth.
# - URL rewrites from ~/dotfiles/git/gitconfig (github -> ssh, zigg, tdna)
#   are preserved verbatim.
let
  # ssh_key paths reflect what gitego writes into config.yaml. Per the D18
  # inventory the private halves for inf/tdna/zigg already live in the
  # 1Password vault — only `.pub` files remain on disk — but gitego itself
  # still records the historical path. We keep them so the generated
  # config.yaml round-trips with the live file. Daily auth flows through
  # IdentityAgent in modules/home-manager/ssh.nix; these paths are
  # informational for gitego CLI commands only.
  # TODO(manager-4.15): once D18 retires ~/.ssh/id_rsa into 1Password,
  # decide whether to drop ssh_key entries entirely from gitego config.
  identities = {
    jry = {
      name = "Jacob Young";
      email = "git@jry.io";
      sshKey = "/Users/CASE/.ssh/id_rsa";
      autoRules = [
        "/Users/CASE/code/personal/statis/"
        "/Users/CASE/code/personal/jryio/"
        "/Users/CASE/code/personal/adr/"
      ];
    };
    inf = {
      name = "Jacob Young";
      email = "git@sancho.studio";
      sshKey = "/Users/CASE/.ssh/infinite-music";
      autoRules = [ "/Users/CASE/code/professional/infinitemusic/" ];
    };
    tdna = {
      name = "Jacob Young";
      email = "jacob.young@tech-dna.net";
      sshKey = "/Users/CASE/.ssh/tdna";
      autoRules = [ "/Users/CASE/code/professional/tdna/" ];
    };
    zigg = {
      name = "Jacob Young";
      email = "jacob.young@ziggiz.ai";
      sshKey = "/Users/CASE/.ssh/zigguratum";
      autoRules = [ "/Users/CASE/code/professional/zigg/" ];
    };
    keybase = {
      name = "Jacob Young";
      email = "jacob@keyba.se";
      sshKey = null; # keybase profile is HTTPS-only per gitego-inventory.md
      autoRules = [ "/Users/CASE/code/professional/keybase/" ];
    };
  };

  activeProfile = "jry";

  # gitego config.yaml renderer. Lines are built explicitly to avoid the
  # multiline-string indent-stripping quirk that produced malformed YAML
  # (per ADR 17). The result matches gitego's own marshaller: profile
  # mappings nest under `profiles:`, optional ssh_key sits inside each
  # profile, and auto_rules is a sequence at the document root.
  renderIdentity = id: i:
    let
      base = [
        "  ${id}:"
        "    name: ${i.name}"
        "    email: ${i.email}"
      ];
      sshLine = lib.optional (i.sshKey != null) "    ssh_key: ${i.sshKey}";
    in
    lib.concatStringsSep "\n" (base ++ sshLine);

  renderAutoRule = id: path:
    lib.concatStringsSep "\n" [
      "  - path: ${path}"
      "    profile: ${id}"
    ];

  gitegoConfigYaml = ''
    profiles:
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderIdentity identities)}
    auto_rules:
    ${lib.concatStringsSep "\n" (lib.flatten
      (lib.mapAttrsToList (id: i: map (renderAutoRule id) i.autoRules) identities))}
    active_profile: ${activeProfile}
  '';

  # Per-profile gitconfig fragment. The jry fragment stays bare to match the
  # live ~/.gitego/profiles/jry.gitconfig (no SSH signing yet); the other
  # four fragments mirror the SSH-signing shape captured in
  # gitego-inventory.md.
  # TODO(manager-4.14): once D10's signing-only GPG mode is fully validated,
  # decide whether the inf/tdna/zigg fragments should keep their per-key
  # ssh-signing overrides or fall back to global GPG signing.
  renderProfileFragment = id: i:
    if id == "jry" then ''
      [user]
          name = ${i.name}
          email = ${i.email}

      [core]
          sshCommand = ssh -i ${i.sshKey}
    ''
    else if id == "keybase" then ''
      [user]
          name = ${i.name}
          email = ${i.email}
    ''
    else ''
      [user]
          name = ${i.name}
          email = ${i.email}
    '';

  includeIfBlocks = lib.flatten (lib.mapAttrsToList
    (id: i: map
      (rule: {
        condition = "gitdir:${rule}";
        path = "${config.home.homeDirectory}/.gitego/profiles/${id}.gitconfig";
      })
      i.autoRules)
    identities);

  profileFiles = lib.mapAttrs'
    (id: i: lib.nameValuePair
      ".gitego/profiles/${id}.gitconfig"
      { text = renderProfileFragment id i; })
    identities;
in
{
  programs.git = {
    enable = true;

    userName = identities.${activeProfile}.name;
    userEmail = identities.${activeProfile}.email;

    signing = {
      signByDefault = true;
      key = "715CED2327899E28";
    };

    includes = includeIfBlocks;

    # Faithful reproduction of ~/dotfiles/git/gitconfig non-identity sections.
    # The `[user] signingkey` line in the live config is redundant with
    # programs.git.signing.key above and is intentionally omitted.
    extraConfig = {
      core = {
        editor = "zed --wait";
        excludesfile = "~/.gitignore";
      };

      credential.helper = "!gitego credential";

      init.defaultBranch = "main";

      push.default = "simple";
      pull.rebase = true;

      diff.tool = "difftastic";
      difftool = {
        prompt = false;
        difftastic.cmd = ''difft "$MERGED" "$LOCAL" "abcdef1" "100644" "$REMOTE" "abcdef2" "100644"'';
      };
      pager.difftool = true;

      filter."lfs" = {
        clean = "git lfs clean -- %f";
        smudge = "git lfs smudge %f";
        required = true;
      };

      "url \"git@github.com:\"".insteadOf = [
        "https://github.com"
        "http://github.com"
      ];

      "url \"git@zigg:zigguratum-core\"".insteadOf = [
        "git@github.com:zigguratum-core"
        "https://github.com/zigguratum-core"
      ];

      "url \"git@tdna:tech-dna\"".insteadOf = "git@github.com:tech-dna";

      "lfs \"customtransfer.xet\"" = {
        path = "git-xet";
        args = "transfer";
        concurrent = true;
      };
    };
  };

  # Render the gitego ledger declaratively. The combined attrset emits one
  # file per profile fragment plus the top-level config.yaml. The
  # gitignore_global asset matches the live ~/.gitignore that core.excludesfile
  # points at; vendored from ~/dotfiles/git/gitignore per D30.
  home.file = profileFiles // {
    ".gitego/config.yaml".text = gitegoConfigYaml;
    ".gitignore".source = ./assets/git/gitignore_global;
  };
}
