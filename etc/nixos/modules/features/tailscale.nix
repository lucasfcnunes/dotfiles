# INFO: https://wiki.nixos.org/wiki/Tailscale
# INFO: https://search.nixos.org/options?show=services.tailscale
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.tailscale =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      tsDomain = "tail3404eb.ts.net";
    in
    {
      sops.secrets = {
        "ts-client-kmJUapyKU311CNTRL" = {
          sopsFile = ../../secrets/tailscale.enc.yaml;
        };
      };
      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
        authKeyFile = "${config.sops.secrets."ts-client-kmJUapyKU311CNTRL".path}";
        authKeyParameters = {
          ephemeral = false;
          preauthorized = true;
        };
        extraUpFlags = [
          "--advertise-tags=tag:computing"
        ];
        # useRoutingFeatures = "client";
        extraSetFlags = [
          # "--netfilter-mode=nodivert"
        ]
        ++ lib.optional config.services.dnscrypt-proxy.enable "--accept-dns=false";
      };
      networking.domain = lib.mkDefault tsDomain;
      networking.search = [
        # INFO: https://tailscale.com/docs/reference/dns-in-tailscale?tab=linux#search-domains
        # INFO: https://login.tailscale.com/admin/dns
        tsDomain
      ];
      networking.firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ];
        allowedUDPPorts = [ config.services.tailscale.port ];
      };
      systemd.services.tailscaled.serviceConfig.Environment = [
      ]
      # INFO: https://tailscale.com/docs/features/firewall-mode
      ++ lib.optional config.networking.nftables.enable "TS_DEBUG_FIREWALL_MODE=nftables";
      # Optimization: Prevent systemd from waiting for network online
      # (Optional but recommended for faster boot with VPNs)
      systemd.network.wait-online.enable = false;
      boot.initrd.systemd.network.wait-online.enable = false;
      services.networkd-dispatcher = {
        enable = true;
        rules."50-tailscale-optimizations" = {
          onState = [ "routable" ];
          script =
            let
              # TODO: dinamically choose the wan interface
              nic = "eth0";
            in
            ''
              ${pkgs.ethtool}/bin/ethtool -K ${nic} rx-udp-gro-forwarding on rx-gro-list off
            '';
        };
      };
    };
}
