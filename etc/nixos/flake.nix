{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-wsl.url = "github:nix-community/nixos-wsl/release-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };
  outputs = inputs@{ self, nixpkgs, nixos-wsl, home-manager, vscode-server, ... }: {
  nixosConfigurations = {
    nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
          # wsl-setting
          ./configuration.nix
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "25.05";
            wsl.enable = true;
          }
          # home-manager settings
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nixos = import ./home.nix;
          }
          # vscode-server settings
          vscode-server.nixosModules.default
          ({ config, pkgs, ...}: {
            services.vscode-server.enable = true;
          })
        ];
      };
    }; 
  };
}
