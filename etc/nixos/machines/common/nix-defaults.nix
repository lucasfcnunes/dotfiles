{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nix-defaults =
    {
      ...
    }:
    {
      system.stateVersion = "25.11";
      i18n.defaultLocale = "en_US.UTF-8";
      nix = {
        settings = {
          trusted-users = [
            "@wheel"
          ];
          # auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          # Cache
          connect-timeout = 5;
          fallback = true;
          accept-flake-config = true;
          substituters = [
            # "https://cache.nixos.org"
            "https://nix-community.cachix.org?priority=41"
            "https://numtide.cachix.org?priority=42"
            # "https://nix-mirror.freetls.fastly.net"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];
          # Download optimization
          http-connections = 128;
          max-substitution-jobs = 128;
          max-jobs = "auto";
        };
        # package = pkgs.nixVersions.latest;
        gc = {
          automatic = true;
          # dates = "daily";
          persistent = true;
          options = "--delete-generations 14d";
          dates = "2weeks";
          # options = "--delete-older-than 10d";
          # options = "--delete-older-than 6d";
        };
        optimise = {
          automatic = true;
          dates = [ "03:45" ];
        };
      };
    };
}
