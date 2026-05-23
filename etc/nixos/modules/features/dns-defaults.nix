{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.dns-defaults =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasIPv6Enabled = config.networking.enableIPv6;
      StateDirectory = "dnscrypt-proxy";
      blocklistBase = builtins.readFile inputs.oisd;
      extraBlocklist = "";
      blocklistTxt = pkgs.writeText "blocklist.txt" ''
        ${extraBlocklist}
        ${blocklistBase}
      '';
      forwardingRulesFile = "nixos/services/networking/forwarding-rules.txt";
    in
    {
      imports = [
        self.nixosModules.dummy-nic
      ];
      environment.etc.${forwardingRulesFile}.text = ''
        # INFO: https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-forwarding-rules.txt

      ''
      + (
        # TODO: move this tailscale section to the tailscale module (in a configurable order)
        let
          tailscaleNameservers =
            "100.100.100.100" + lib.optionalString hasIPv6Enabled ", [fd7a:115c:a1e0::53]";
        in
        lib.optionalString config.services.tailscale.enable ''
          # INFO: https://tailscale.com/docs/reference/quad100
          # INFO: https://tailscale.com/docs/reference/faq/dns-resolv-conf
          ts.net ${tailscaleNameservers}

        ''
      );
      networking = {
        nameservers = lib.mkDefault (
          [
            config.my.dummy-nic.lo-proxy0.ipv4
          ]
          ++ lib.optional hasIPv6Enabled "::1"
        );
        networkmanager.dns = "none";
        dhcpcd.extraConfig = "nohook resolv.conf";
        # resolvconf.enable = true;
        # resolvconf.useLocalResolver = true;
      };
      # TODO: investigate if this can be enabled together with dnscrypt-proxy
      # TODO: resolved.conf missing line `options edns0 trust-ad`
      services.resolved.fallbackDns = [ ];
      services.resolved.extraConfig = ''
        DNSStubListener=no
      '';
      services.resolved.dnssec = "true";
      # services.resolved.dnsovertls = true;
      # environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";
      # services.resolved.settings.Resolve.FallbackDNS = [ ];
      services.dnscrypt-proxy = {
        enable = true;
        # INFO: https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
        settings = {
          listen_addresses = [
            "127.0.0.1:53"
          ]
          ++ lib.optional hasIPv6Enabled "[::1]:53";
          ipv6_servers = hasIPv6Enabled;
          block_ipv6 = !hasIPv6Enabled;
          require_dnssec = true;
          require_nolog = false;
          require_nofilter = true;
          # query_log.file = "/var/log/dnscrypt-proxy/query.log";
          blocked_names.blocked_names_file = blocklistTxt;
          sources.public-resolvers = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
              "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
              "https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers@master/v3/public-resolvers.md"
            ];
            cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md";
            minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
          };
          # INFO: https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
          server_names = [
            "cloudflare"
            # "google"
          ]
          ++ (
            if hasIPv6Enabled then
              [
                "cloudflare-ipv6"
                # "google-ipv6"
              ]
            else
              [ ]
          );
          forwarding_rules = config.environment.etc.${forwardingRulesFile}.source;
        };
      };
      systemd.services.dnscrypt-proxy.serviceConfig.StateDirectory = StateDirectory;
    };
}
