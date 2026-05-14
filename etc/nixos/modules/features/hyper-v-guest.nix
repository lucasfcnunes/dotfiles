# INFO: https://github.com/NixOS/nixos-hardware/tree/master/microsoft/hyper-v
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.hyper-v-guest =
    {
      ...
    }:
    {
      virtualisation.hypervGuest.enable = true;
      # REQUIRED - see: https://github.com/nixos/nixpkgs/issues/9899
      boot.initrd.kernelModules = [
        "hv_vmbus"
        "hv_storvsc"
      ];
      # RECOMMENDED
      # - use 800x600 resolution for text console, to make it easy to fit on screen
      boot.kernelParams = [ "video=hyperv_fb:800x600" ]; # https://askubuntu.com/a/399960
      # - avoid a problem with `nix-env -i` running out of memory
      boot.kernel.sysctl."vm.overcommit_memory" = "1"; # https://github.com/NixOS/nix/issues/421
      # UNKNOWN - not sure if below are needed; were suggested for VirtualBox and I used them
      # boot.loader.grub.device = "/dev/sda";
      boot.initrd.checkJournalingFS = false;
    };
}
