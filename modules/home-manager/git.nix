{ config, lib, pkgs, vars, ... }:

# Declarative git + gitego configuration per MIGRATION.md D25.
#
# - Identities live in lib/vars.nix. The set started as the five taken
#   verbatim from .ai/inventory/gitego-config.yaml (jry/inf/tdna/zigg/keybase);
#   cloudx was added 2026-07-27 and inf/zigg retired 2026-07-29, leaving
#   jry/tdna/keybase/cloudx.
# - The active profile is `jry`; its [user] block becomes the global git
#   identity, which matches the live ~/.gitconfig.
# - Global signing stays GPG key 715CED2327899E28 per D10 (the only
#   [SC]-capable secret key in ~/.gnupg), so repos outside every auto_rule
#   tree — this repo, ~/dotfiles — still GPG-sign. Any identity with a
#   `signingKey` in lib/vars.nix instead signs with that SSH key via
#   1Password's op-ssh-sign, scoped to its auto_rule trees by the includeIf
#   fragment. Today: jry, tdna, cloudx. keybase has no SSH key and inherits
#   the global GPG key.
# - includeIf rules are generated from the same identity table that feeds
#   the gitego YAML, so there is exactly one source of truth.
# - URL rewrites from ~/dotfiles/git/gitconfig (github -> ssh, tdna) are
#   preserved verbatim.
let
  # ssh_key paths reflect what gitego writes into config.yaml. Per the D18
  # inventory tdna's private half already lives in the 1Password vault — only
  # the `.pub` file remains on disk — but gitego itself still records the
  # historical path. We keep them so the generated config.yaml round-trips
  # with the live file. Daily auth flows through IdentityAgent in
  # modules/home-manager/ssh.nix; these paths are informational for gitego
  # CLI commands only.
  # TODO: once D18 retires ~/.ssh/id_rsa into 1Password,
  # decide whether to drop ssh_key entries entirely from gitego config.
  identities = vars.identities;
  activeProfile = vars.activeIdentity;

  # gitego config.yaml renderer. Lines are built explicitly to avoid the
  # multiline-string indent-stripping quirk that produced malformed YAML.
  # The result matches gitego's own marshaller: profile
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

  # Per-profile gitconfig fragment. gitego's own CLI only knows
  # name/email/username/ssh_key/pat, so signing is not something gitego can
  # express — but the includeIf fragments it pulls in are the supported hook,
  # and this module owns their contents. An identity with a `signingKey`
  # overrides the global GPG signing (vars.signing.gpgKey) with SSH-format
  # signing through 1Password's op-ssh-sign inside its auto_rule path trees.
  # This restores (and extends to jry) the hand-written blocks the pre-migration
  # fragments carried — see ~/.gitego/profiles/*.gitconfig.hm-backup.
  renderProfileFragment = id: i:
    let
      userBlock = [
        "[user]"
        "    name = ${i.name}"
        "    email = ${i.email}"
      ] ++ lib.optional (i.signingKey != null) "    signingkey = ${i.signingKey}";

      sshSigningBlock = lib.optionals (i.signingKey != null) [
        ""
        "[gpg]"
        "    format = ssh"
        ""
        "[gpg \"ssh\"]"
        "    program = \"${vars.signing.opSshSign}\""
        "    allowedSignersFile = ${vars.signing.allowedSignersFile}"
      ];

      # gitego profiles select authorship and signing, not SSH transport
      # identity. Pointing SSH at the public key constrains the 1Password agent
      # to the identity authorized for this profile's repositories.
      coreBlock = lib.optionals (i.sshAuthKeyFile != null) [
        ""
        "[core]"
        "    sshCommand = ssh -o IdentitiesOnly=yes -i ${i.sshAuthKeyFile}"
      ];
    in
    lib.concatStringsSep "\n" (userBlock ++ sshSigningBlock ++ coreBlock) + "\n";

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

    signing = {
      signByDefault = true;
      key = vars.signing.gpgKey;
    };

    includes = includeIfBlocks;

    # Faithful reproduction of ~/dotfiles/git/gitconfig non-identity sections.
    # The `[user] signingkey` line in the live config is redundant with
    # programs.git.signing.key above and is intentionally omitted.
    settings = {
      user = {
        name = identities.${activeProfile}.name;
        email = identities.${activeProfile}.email;
      };

      # Use the nvim executable: it always loads the managed LazyVim config,
      # unlike the interactive-only `lazyvim` alias.
      core = {
        editor = "nvim";
        excludesfile = "~/.gitignore";
      };
      sequence.editor = "nvim";

      credential.helper = "!gitego credential";

      init.defaultBranch = "main";

      push.default = "simple";
      pull.rebase = true;

      rerere = {
        enabled = true;
        autoupdate = true;
      };

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

      # NOTE: host alias `tdna` is not defined in any ssh_config (neither the
      # legacy ~/.ssh/config nor modules/home-manager/ssh.nix, which uses the
      # `github-tdna` naming). Preserved verbatim from ~/dotfiles/git/gitconfig
      # pending confirmation that anything still relies on it.
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
