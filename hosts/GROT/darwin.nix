{ ... }:

{
  # GROT is an always-on, Tailscale-only remote server (modules/darwin/server.nix).
  server = {
    enable = true;
    # Off while Rippling adopts Tailscale.app and 1Password (2026-11-11): the
    # watchdog reopens them within 120 s of any quit. Set true to restore.
    appWatchdog.enable = false;
    authorizedKeys = [
      # "GROT SSH key" in 1Password.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKD/Izhbyw+nLG4I5SR+EQZQsxdehD46adBqBKE8pc8I GROT SSH key"
      # Legacy id_rsa (already in ~/.ssh/authorized_keys; also in 1Password).
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5SmJeZdvn90DK9uZW3Zxrmr/dqfz0fzMsaqNYdeOlAJDEZrGSgyuT7vNa2KxomS5lSqm/GvygpWYS1/qwrz10v2qLsICN3LTKcbqczE9/wtg+jqjXYtd4BgIA2x9qHfyWGAOoH0wluab5Yae4QxQWWln4uCyHQcISKYx1dALS5TIejIbHrDBhPS3fkqb2TD985fBTfChpA93gwc31yvZi+05VZ1tEL+mcnse0cHtFmx0SP818sairtuRIPcsgXSsIO8mrZHtzez7IXAhqZKiZCRQuQXue3BIkgcdPzmCU1DmIl7tl+MvQe7mo78heJXO5LtFKjMg5FP4amsbzb+DSWyFe1ckhJN8tYaJLcfkU59hGTyQnCig6BLXfNExSpbPfZ0zWH9IvH1jIg9npGQ2+9vh+/z69fSjH5tD8X+Jwh548XPmnsWtr/3ta0aAWE7i4k6dEspAvemFFRSlfHaXNZD6lNSbYNGEfd4Y8KPncIE9lFJyqkpeI8OQqApRarQ/4UixYrZhfS9RH0xLhiu/3gVtZDmQjOvAl0BFSnw9lUEO+Sc8cfH72ta0zdRmfyGH9KfYn1iAF1yVplUkp8nVSa0TAH5L9bC3DyUXVWrwzz4t5pI1PJIfmYL2LBaIRgo/4Oewbtp9Gk5xOLOq8v6PWvNAyKBl5XjyUqn+h0O+c+Q== id_rsa"
    ];
  };
}
