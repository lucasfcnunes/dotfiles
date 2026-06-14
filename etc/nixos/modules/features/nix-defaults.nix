{
  self,
  inputs,
  withSystem,
  ...
}:
{
  perSystem =
    {
      # config,
      # lib,
      pkgs,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          self.overlays.nixpkgs-unstable
        ];
        config = {
          allowUnfree = false;
          # allowUnsupportedSystem = lib.mkDefault (if (config ? wsl && config.wsl.enable) then true else true);
        };
      };
      formatter = pkgs.nixfmt-tree;
    };
  flake.nixosModules.nix-defaults =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.std-compliance
        # inputs.nixpkgs.nixosModules.readOnlyPkgs
        (
          { config, ... }:
          {
            nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);
          }
        )
      ];
      nix = {
        nixPath = [
          "nixpkgs=${inputs.nixpkgs}"
          "nixpkgs-unstable=${inputs.nixpkgs-unstable}"
        ];
        settings = {
          trusted-users = [
            "@wheel"
          ];
          # auto-optimise-store = true;
          experimental-features = [
            "flakes"
            "nix-command"
            "pipe-operators"
          ];
          connect-timeout = 5;
          fallback = true;
          accept-flake-config = false; # INFO: https://notashelf.dev/posts/reject-flake-content/
          substituters = [
            "https://cache.nixos.org?priority=10"
            "https://nix-mirror.freetls.fastly.net?priority=10"
          ];
          trusted-substituters = [
            "https://nix-community.cachix.org?priority=41"
            "https://numtide.cachix.org?priority=42"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];
          http-connections = 128;
          max-substitution-jobs = 128;
          max-jobs = "auto";
          download-buffer-size = 524288000;
        };
        # package = pkgs.nixVersions.latest;
        gc = {
          automatic = lib.mkDefault true;
          persistent = true;
          options = "--delete-older-than 20d";
          # dates = "weekly";
          dates = "*-*-01,15 00:00:00";
        };
        optimise = {
          automatic = lib.mkDefault true;
          dates = [ "03:45" ];
        };
      };
      environment.systemPackages = with pkgs; [
        nixfmt-tree
        nixfmt
        nixd
      ];
    };
}
