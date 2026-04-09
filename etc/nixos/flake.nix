{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-wsl.url = "github:nix-community/nixos-wsl/release-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    deploy-rs.url = "github:serokell/deploy-rs";
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      vscode-server,
      deploy-rs,
      ...
    }:
    {
      nixosConfigurations = {
        nixos-wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # wsl-setting
            ./machines/nixos-wsl/configuration.nix
            nixos-wsl.nixosModules.default
            {
              system.stateVersion = "25.11";
              wsl.enable = true;
              wsl.docker-desktop.enable = true;
              wsl.defaultUser = "lucasfcnunes";
            }
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
      };
      deploy.nodes = {
        nixos-wsl = {
          hostname = "nixos-wsl";
          profiles.system = {
            user = "lucasfcnunes";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixos-wsl;
          };
        };
      };
      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
