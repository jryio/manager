{
  config,
  lib,
  pkgs,
  ...
}:

{
  # tig's main view has no signature column (supported columns: author, date,
  # commit-title, id, line-number, ref), so signing status is shown on demand:
  # V in the main view prints the highlighted commit's signature through the
  # pager. The commit log itself is covered by the `gls` zsh function in
  # shell/init.zsh.
  xdg.configFile."tig/config".text = ''
    # V: show the GPG/SSH signature of the highlighted commit.
    bind main V !git show --show-signature --no-patch --format=fuller %(commit)
  '';
}
