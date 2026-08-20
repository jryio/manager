{
  config,
  lib,
  pkgs,
  ...
}:

{
  # tig's main view has no signature column (supported columns: author, date,
  # commit-title, id, line-number, ref), so signing status is shown on demand:
  # V in the main view verifies the highlighted commit. verify-commit exits 0
  # only on a good signature; anything else is labelled explicitly, because
  # `git show --show-signature` just omits the signature block on unsigned
  # commits without saying so. The commit log itself is covered by the `gls`
  # zsh function in shell/init.zsh.
  xdg.configFile."tig/config".text = ''
    # V: show the GPG/SSH signature of the highlighted commit.
    bind main V !sh -c 'git verify-commit "$1" 2>&1 && echo "SIGNED" || echo "UNSIGNED (or signature unverifiable)"' sh %(commit)
  '';
}
