{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-01-disko-config =
    {
      lib,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];
      disko.devices = {
        disk = {
          sda = {
            device = "/dev/disk/by-id/scsi-360022480088f80508d95da3ca9975270";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  uuid = "31e58b3a-54c4-42a5-a98a-a2553d5732ee";
                  label = "boot";
                  type = "EF00";
                  size = "1G";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [
                      # "umask=0077"
                      "fmask=0022"
                      "dmask=0022"
                    ];
                  };
                };
                root = {
                  uuid = "96fe526f-2118-459c-8646-543340c873d4";
                  label = "nixos";
                  size = "100%";
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
          sdb = {
            device = "/dev/disk/by-id/scsi-3600224806bfb6f9a865cb17e346c1bc6";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                home = {
                  uuid = "1b642b5d-0be1-42e4-8508-67e9d44e25cd";
                  label = "home";
                  size = "100%";
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
          # sdc = {
          #   device = "/dev/disk/by-id/scsi-3600224804d7774e7dfb39316089a3884";
          #   type = "disk";
          # };
        };
      };
    };
}
