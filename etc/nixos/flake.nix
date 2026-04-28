{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      disko,
      nixos-wsl,
      home-manager,
      vscode-server,
      deploy-rs,
      sops-nix,
      ...
    }@inputs:
    let
      overlay-pkgs-unstable = (
        final: prev: {
          unstable = import nixpkgs-unstable {
            inherit (final) config;
            inherit (final.stdenv.hostPlatform) system;
          };
        }
      );
      deployPkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          deploy-rs.overlays.default
          (self: super: {
            deploy-rs = {
              inherit (nixpkgs.legacyPackages.x86_64-linux) deploy-rs;
              lib = super.deploy-rs.lib;
            };
          })
        ];
      };
    in
    {
      nixosConfigurations = {
        nixos-wsl = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ overlay-pkgs-unstable ]; }
            ./machines/nixos-wsl/configuration.nix
            # disko.nixosModules.disko
            nixos-wsl.nixosModules.default
            {
              system.stateVersion = "25.11";
              wsl.enable = true;
              wsl.docker-desktop.enable = true;
              wsl.defaultUser = "lucasfcnunes";
            }
            # sops-nix
            sops-nix.nixosModules.sops
            # home-manager settings
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.lucasfcnunes = import ./machines/nixos-wsl/home.nix;
            }
            # vscode-server settings
            vscode-server.nixosModules.default
            (
              { config, pkgs, ... }:
              {
                services.vscode-server.enable = true;
              }
            )
          ];
        };
        nixos-01 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ overlay-pkgs-unstable ]; }
            ./machines/nixos-01/configuration.nix
            disko.nixosModules.disko
            # sops-nix
            sops-nix.nixosModules.sops
            # home-manager settings
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.lucasfcnunes = import ./machines/nixos-01/home.nix;
            }
            # vscode-server settings
            vscode-server.nixosModules.default
            (
              { config, pkgs, ... }:
              {
                services.vscode-server.enable = true;
              }
            )
          ];
        };
      };
      deploy.nodes = {
        nixos-wsl = {
          hostname = "nixos-wsl";
          profiles.system = {
            user = "lucasfcnunes";
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.nixos-wsl;
          };
        };
        nixos-01 = {
          hostname = "nixos-01";
          # hostname = "nixos-01.tail3404eb.ts.net";
          sshUser = "lucasfcnunes";
          # interactiveSudo = true;
          profiles.system = {
            user = "root";
            autoRollback = false;
            magicRollback = false;
            # remoteBuild = true;
            activationTimeout = 600;
            confirmTimeout = 60;
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.nixos-01;
          };
        };
      };
      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
