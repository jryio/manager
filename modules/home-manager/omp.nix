{ config, lib, ... }:

let
  configPath = "${config.home.homeDirectory}/.omp/agent/config.yml";
  seed = ./assets/omp/config.yml;
in
{
  home.activation.ompConfigSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${configPath}"
    if [ -L "$target" ] && [[ "$(/usr/bin/readlink "$target")" == /nix/store/* ]]; then
      /bin/rm -f "$target"
    fi
    if [ ! -e "$target" ]; then
      /bin/mkdir -p "$(/usr/bin/dirname "$target")"
      /usr/bin/install -m 0644 "${seed}" "$target"
    fi
  '';
}
