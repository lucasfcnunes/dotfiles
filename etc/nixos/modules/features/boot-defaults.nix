{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.boot-defaults =
    {
      lib,
      pkgs,
      ...
    }:
    {
      # boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.enable = true;
    };
}
