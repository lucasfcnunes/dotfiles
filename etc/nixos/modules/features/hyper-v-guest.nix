# INFO: https://github.com/NixOS/nixos-hardware/tree/master/microsoft/hyper-v
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.hyper-v-guest-lib =
    {
      config,
      lib,
      ...
    }:
    {
      options.lucasfcnunesLib = lib.mkOption {
        type = lib.types.raw;
        readOnly = true;
      };
      config.lucasfcnunesLib = {
        hvDiskByLocation =
          {
            location ? 0, # lun
            storageControllerId ? 0,
            facterReport ? config.hardware.facter.report,
          }:
          let
            storage_controller =
              facterReport.hardware.storage_controller |> (l: builtins.elemAt l storageControllerId);
            sysfs_bus_id = (storage_controller.sysfs_bus_id |> builtins.replaceStrings [ "-" ] [ "" ]);
            bus = storage_controller.sysfs_id |> builtins.split "/" |> (l: builtins.elemAt l 10);
            mode = bus |> builtins.split ":" |> (l: builtins.elemAt l 0);
          in
          if mode == "VMBUS" then
            "/dev/disk/by-path/acpi-${bus}-vmbus-${sysfs_bus_id}-lun-${toString location}"
          else if mode == "MSFT1000" then
            "/dev/disk/by-path/acpi-${bus}-scsi-0:0:0:${toString location}"
          else
            throw "Unknown sysfs_bus_id mode: ${sysfs_bus_id}";
      };
    };
  flake.nixosModules.hyper-v-guest =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.hyper-v-guest-lib
      ];
      virtualisation.hypervGuest.enable = true;
      # REQUIRED - see: https://github.com/nixos/nixpkgs/issues/9899
      boot.initrd.kernelModules = [
        "hv_vmbus"
        "hv_storvsc"
      ];
      # RECOMMENDED
      # - use 1200x900 resolution for text console, to make it easy to fit on screen
      boot.kernelParams = [ "video=hyperv_fb:1200x900" ]; # https://askubuntu.com/a/399960
      # - avoid a problem with `nix-env -i` running out of memory
      boot.kernel.sysctl."vm.overcommit_memory" = "1"; # https://github.com/NixOS/nix/issues/421
      # UNKNOWN - not sure if below are needed; were suggested for VirtualBox and I used them
      # boot.loader.grub.device = "/dev/sda";
      boot.initrd.checkJournalingFS = false;
      # INFO: https://wiki.nixos.org/wiki/Remote_Desktop#:~:text=%5B%203389%20%5D%3B-,XRDP%20under%20Hyper%2DV%20with%20enhanced%20session%20mode,-%5Bedit%20%7C
      services.xrdp.extraConfDirCommands = ''
        substituteInPlace $out/xrdp.ini \
          --replace-fail 'port=3389' 'port=vsock://-1:3389' \
          --replace-fail '#vmconnect=true' 'vmconnect=true' \
          --replace-fail 'security_layer=negotiate' 'security_layer=rdp' \
          --replace-fail 'crypt_level=high' 'crypt_level=none' \
          --replace-fail 'bitmap_compression=true' 'bitmap_compression=false'
      '';
      systemd.services.xrdp.serviceConfig.ExecStart =
        lib.mkForce "${pkgs.xrdp}/bin/xrdp --nodaemon --config /etc/xrdp/xrdp.ini";
    };
}
