# TODO: revise this configuration for the specific hardware and requirements of the AW16 system
{
  self,
  ...
}:
{
  flake.nixosModules.aw16lucasfcnunes-specifics =
    {
      config,
      pkgs,
      ...
    }:
    {
      # Kernel 6.12+ / latest recommended for MediaTek MT7925 & Intel Core 7 240H
      boot.kernelPackages = pkgs.linuxPackages_latest;
      nixpkgs.config.allowUnfree = true;

      # NVIDIA RTX & Hybrid Graphics
      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = true; # Required for RTX 50-series; works on RTX 30/40-series
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      services.thermald.enable = true;
      services.power-profiles-daemon.enable = true;
    };
}
