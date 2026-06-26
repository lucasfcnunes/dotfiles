# TODO: make this the default disk configuration for all nixos-* hosts
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-01-disko-config =
    {
      config,
      lib,
      ...
    }:
    let
      partitionPrefix = config.networking.hostId;
      storageDevicePath = config.lucasfcnunesLib.hvDiskByLocation;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];
      disko.devices = {
        disk = {
          lun-0 = {
            device = storageDevicePath { location = 0; };
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
                  size = "100%";
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
              };
            };
          };
          lun-1 = {
            device = storageDevicePath { location = 1; };
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
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
          # lun-(\d+) = {
          #   device = storageDevicePath { location = $1; };
          #   type = "disk";
          # };
        };
      };
    };
}
