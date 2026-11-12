# TODO: make this the default disk configuration for all nixos-* hosts
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.aw16lucasfcnunes-disko-config =
    {
      config,
      lib,
      ...
    }:
    let
      partitionPrefix = config.networking.hostId;
      # storageDevicePath = config.lucasfcnunesLib.hvDiskByLocation;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];
      disko.devices = {
        disk = {
          lun-0 = {
            # device = storageDevicePath { location = 0; };
            device = "/dev/nvme0n1";
            # "/dev/disk/by-id/nvme-2650_Micron_512GB_26175821FC34",
            # "/dev/disk/by-id/nvme-2650_Micron_512GB_26175821FC34_1",
            # "/dev/disk/by-id/nvme-eui.00a075015821fc34",
            # "/dev/disk/by-path/pci-0000:03:00.0-nvme-1",
            # "/dev/nvme0n1"
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
                  size = "200G";
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
                  size = "100G";
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
