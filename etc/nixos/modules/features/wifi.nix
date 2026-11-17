{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.wifi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      sops.secrets = {
        "wireless.conf" = {
          sopsFile = ../../secrets/wifi.enc.yaml;
        };
      };
      networking.networkmanager.enable = false;
      networking.useNetworkd = true;
      # networking.wireless.iwd.enable = true;
      networking.wireless = {
        enable = true;
        # Allows runtime configuration via wpa_cli / wpa_gui (optional)
        userControlled = true;

        # Declarative Wi-Fi networks (recommended)
        networks = {
          "FERNANDO" = {
            pskRaw = "ext:psk_FERNANDO";
          };
          "CIVITAS" = {
            pskRaw = "ext:psk_CIVITAS";
          };
        };
        secretsFile = "${config.sops.secrets."wireless.conf".path}";
      };
      users.users.lucasfcnunes.extraGroups = [
        "wheel"
        "wpa_supplicant"
      ];
      systemd.network = {
        enable = true;
        networks."10-wifi" = {
          matchConfig.Name = "wl*";
          networkConfig = {
            DHCP = "yes";
            IgnoreCarrierLoss = "3s";
          };
          dhcpV4Config.RouteMetric = 100;
        };
      };

      # networking.useNetworkd = lib.mkForce false;
      # systemd.network.enable = lib.mkForce false;
      # networking.useDHCP = lib.mkForce true;
      # networking.networkmanager = {
      #   enable = lib.mkForce true;
      #   wifi.backend = "iwd";
      # };
      # networking.wireless.iwd.enable = true;

      # users.users.lucasfcnunes.extraGroups = [ "networkmanager" ];

      # environment.systemPackages = with pkgs; [
      #   iw
      #   iwd
      #   networkmanager
      #   bluez
      # ];
    };
}
