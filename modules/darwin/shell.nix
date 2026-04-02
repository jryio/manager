{ host, ... }:

{
  programs.zsh.enable = true;

  users.users.${host.username}.shell = "/bin/zsh";
}
