{ config, lib, pkgs, ... }:

# Per D26 / manager-4.18: /etc/hosts blocklist.
#
# nix-darwin's networking module does NOT expose networking.hosts or
# networking.extraHosts (NixOS-only). The 1267-entry blocklist for
# Facebook/Instagram/WhatsApp/Messenger CDN/edge previously lived here;
# committed to .ai/inventory/etc-hosts-blocks.txt as the source of truth.
#
# TODO(manager-4.18): land the blocklist via a system.activationScripts
# block (append/strip managed lines in /etc/hosts at activation) once the
# rest of the flake evaluates cleanly. Deferred to avoid blocking the
# testaccount validation gate.

{ }
