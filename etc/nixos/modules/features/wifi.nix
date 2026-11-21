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
      networking.networkmanager = {
        enable = true;
        # wifi.backend = "wpa_supplicant"; # ! doesn't seems to work
        wifi.backend = "iwd";
        unmanaged = [
          # https://networkmanager.dev/docs/api/latest/NetworkManager.conf.html#device-spec
          "*"
          # "except:interface-name:wl*"
          "except:type:wifi"
        ];
      };
      networking.wireless = {
        enable = !config.networking.networkmanager.enable;
        # Allows runtime configuration via wpa_cli / wpa_gui (optional)
        userControlled = true;
        # allowAuxiliaryImperativeNetworks = true;
        # Declarative Wi-Fi networks (recommended)
        networks = {
          "FERNANDO" = {
            pskRaw = "ext:psk_FERNANDO";
          };
          "CIVITAS" = {
            pskRaw = "ext:psk_CIVITAS";
          };
          "VISITANTES_COR" = {
            pskRaw = "ext:psk_VISITANTES_COR";
          };
        };
        secretsFile = "${config.sops.secrets."wireless.conf".path}";
      };
      users.users.lucasfcnunes.extraGroups = [
        "wheel"
      ]
      ++ (
        if config.networking.networkmanager.enable then
          [
            "networkmanager"
            config.networking.networkmanager.wifi.backend
          ]
        else
          [ ]
      );
      systemd.network = {
        networks."10-wifi" = {
          enable = config.networking.useNetworkd && config.networking.wireless.enable;
          matchConfig.Name = "wl*";
          networkConfig = {
            DHCP = "yes";
            IgnoreCarrierLoss = "3s";
          };
          dhcpV4Config.RouteMetric = 100;
        };
      };
      environment.systemPackages = with pkgs; [
        networkmanager
        # wpa_supplicant
        # wpa_supplicant_gui
        iw
        iwd
        # bluez
      ];

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
