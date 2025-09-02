{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../common/ssh.nix
    ../common/users.nix
  ];

  sdImage.compressImage = false;

  networking.useDHCP = true;
  networking.firewall.enable = false;

  nix.trustedUsers = ["lucasfcnunes"];

  services.openssh = {
    enable = true;
    openFirewall = true;
    permitRootLogin = "yes";
  };

  users = {
    users = {
      lucasfcnunes = {
        password = "lucasfcnunes";
      };
      root = {
        password = "lucasfcnunes";
      };
    };
  };
}
