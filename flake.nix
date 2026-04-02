{
  description = "macOS bootstrap with Determinate Nix, nix-darwin, and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      lib = nixpkgs.lib;
      hostsDir = ./hosts;
      hostEntries = builtins.readDir hostsDir;
      hostNames = lib.filter (
        name:
          hostEntries.${name} == "directory"
          && builtins.pathExists (hostsDir + "/${name}/default.nix")
      ) (builtins.attrNames hostEntries);

      mkDarwinConfiguration = hostName:
        let
          hostDir = hostsDir + "/${hostName}";
          host = import (hostDir + "/default.nix");
          hostDarwinModule = hostDir + "/darwin.nix";
          hostHomeModule = hostDir + "/home.nix";
        in
        nix-darwin.lib.darwinSystem {
          system = host.system;
          specialArgs = {
            inherit inputs host hostName;
          };
          modules = [
            inputs.determinate.darwinModules.default
            home-manager.darwinModules.home-manager
            ./modules/darwin/base.nix
            {
              # Preserve existing dotfiles on first activation instead of
              # replacing them or requiring a destructive cleanup step.
              home-manager.backupFileExtension = "hm-backup";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs host hostName;
              };
              home-manager.users.${host.username} = { ... }: {
                imports =
                  [ inputs.determinate.homeManagerModules.default
                    ./modules/home-manager/base.nix
                  ]
                  ++ lib.optionals (builtins.pathExists hostHomeModule) [ hostHomeModule ];
              };
            }
          ] ++ lib.optionals (builtins.pathExists hostDarwinModule) [ hostDarwinModule ];
        };
    in
    {
      darwinConfigurations = lib.genAttrs hostNames mkDarwinConfiguration;

      formatter = lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
