{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.dummy-nic =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.dummy-nic;
      hasIPv6Enabled = config.networking.enableIPv6;
    in
    {
      options = {
        my.dummy-nic.lo-proxy0 = {
          ipv4 = lib.mkOption {
            type = lib.types.str;
            default = "169.254.20.20";
            description = "IPv4 address for the lo-proxy0 network interface.";
            example = "e.g. 169.254.20.20";
          };
          ipv6 = lib.mkOption {
            type = lib.types.str;
            default = "fd00::2020";
            description = "IPv6 address for the lo-proxy0 network interface.";
            example = "e.g. fd00::2020";
          };
        };
      };
      config = {
        boot.kernelModules = [
          "dummy"
        ];
        # networking.interfaces.lo-proxy0 = {
        #   virtual = true;
        #   ipv4.addresses = [
        #     {
        #       address = cfg.lo-proxy0.ipv4;
        #       prefixLength = 32;
        #     }
        #   ];
        #   ipv6.addresses = lib.optional hasIPv6Enabled [
        #     {
        #       address = cfg.lo-proxy0.ipv6;
        #       prefixLength = 128;
        #     }
        #   ];
        # };
        networking.useNetworkd = true;
        networking.useDHCP = false;
        networking.networkmanager.enable = false;
        services.resolved.enable = true;
        networking.resolvconf.enable = false;
        systemd.network = {
          enable = true;
          netdevs."10-lo-proxy0" = {
            netdevConfig = {
              Name = "lo-proxy0";
              Kind = "dummy";
            };
          };
          networks."10-lo-proxy0" = {
            matchConfig.Name = "lo-proxy0";
            address = [
              "${cfg.lo-proxy0.ipv4}/32"
            ]
            ++ lib.optional hasIPv6Enabled "${cfg.lo-proxy0.ipv6}/128";
          };
          networks."20-wired" = {
            matchConfig.Name = "en* eth*";
            networkConfig.DHCP = "yes";
            dhcpV4Config.UseDNS = false;
            dhcpV6Config.UseDNS = false;
          };
        };
        # networking.firewall.trustedInterfaces = [
        #   "lo-proxy0"
        # ];
        networking.firewall.interfaces."lo-proxy0" = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
        networking.nameservers = [
          cfg.lo-proxy0.ipv4
        ]
        ++ lib.optional hasIPv6Enabled cfg.lo-proxy0.ipv6;
        services.dnscrypt-proxy.settings.listen_addresses = [
          "${cfg.lo-proxy0.ipv4}:53"
        ]
        ++ lib.optional hasIPv6Enabled "[${cfg.lo-proxy0.ipv6}]:53";
      };
    };
}
