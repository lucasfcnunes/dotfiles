# TODO: make this the default disk configuration for all nixos-* hosts
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.dkplucasfcnunes-disko-config =
    {
      config,
      lib,
      ...
    }:
    let
      partitionPrefix = config.networking.hostId;
      # ! vmbus uuid may be not the best idea...
      VMBus00DevicePrefix =
        "/dev/disk/by-path/acpi-VMBUS:00-vmbus-"
        + (
          (builtins.elemAt config.hardware.facter.report.hardware.storage_controller 00).sysfs_bus_id
          |> lib.replaceStrings [ "-" ] [ "" ]
        );
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];
      disko.devices = {
        disk = {
          lun-0 = {
            device = "${VMBus00DevicePrefix}-lun-0";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  label = "${partitionPrefix}-boot";
                  type = "EF00";
                  size = "1G";
                  # priority = 1;
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [
                      "umask=0077"
                      "dmask=0077"
                      # "fmask=0022"
                      # "dmask=0022"
                    ];
                  };
                };
                root = {
                  label = "${partitionPrefix}-nixos";
                  size = "75G";
                  # priority = 2;
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                    # mountOptions = [
                    #   "x-initrd.mount"
                    # ];
                  };
                };
                home = {
                  label = "${partitionPrefix}-home";
                  size = "100%";
                  # priority = 3;
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/home";
                    mountOptions = [
                      "defaults"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
}
