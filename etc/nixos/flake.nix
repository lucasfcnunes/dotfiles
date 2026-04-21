{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-wsl.url = "github:nix-community/nixos-wsl/release-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      vscode-server,
      deploy-rs,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        nixos-wsl = nixpkgs.lib.nixosSystem {
          system = "${system}";
          specialArgs = { inherit inputs; };
          modules = [
            ./machines/nixos-wsl/configuration.nix
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
          system = "${system}";
          specialArgs = { inherit inputs; };
          modules = [
            ./machines/nixos-01/configuration.nix
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
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.nixos-wsl;
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
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.nixos-01;
          };
        };
      };
      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
