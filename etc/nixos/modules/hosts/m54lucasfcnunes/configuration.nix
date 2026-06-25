# TODO: it's a wip
{
  self,
  inputs,
  ...
}:
{
  flake.nixOnDroidModules.m54lucasfcnunes-configuration =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
      ];
      system.stateVersion = "24.05";
      # networking.hostId = "af9b7fd5";
      # networking.hostName = "m54lucasfcnunes";
      nix.extraOptions = ''
        experimental-features = nix-command flakes pipe-operators
      '';
      time.timeZone = "UTC";
      # user.userName = "lucasfcnunes";
      environment.packages = with pkgs; [
        vim
        wget
        git
      ];
      environment.etcBackupExtension = ".bak";
      home-manager = {
        backupFileExtension = "hm-bak";
        useGlobalPkgs = true;
      };
      home-manager.config =
        {
          pkgs,
          ...
        }:
        {
          home.stateVersion = "24.05";

        };
      # home-manager.config = ./home.nix;
    };
}
