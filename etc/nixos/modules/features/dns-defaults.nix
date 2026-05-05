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
      hasIPv6Internet = config.networking.enableIPv6;
      StateDirectory = "dnscrypt-proxy";
      blocklist_base = builtins.readFile inputs.oisd;
      extraBlocklist = "";
      blocklist_txt = pkgs.writeText "blocklist.txt" ''
        ${extraBlocklist}
        ${blocklist_base}
      '';
    in
    {
      networking = {
        nameservers = [
          "127.0.0.1"
        ]
        ++ lib.optional hasIPv6Internet "::1";
        # If using dhcpcd:
        dhcpcd.extraConfig = "nohook resolv.conf";
        # If using NetworkManager:
        networkmanager.dns = "none";
      };
      services.resolved.enable = false;
      services.dnscrypt-proxy = {
        enable = true;
        # INFO: https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
        settings = {
          ipv6_servers = hasIPv6Internet;
          block_ipv6 = !hasIPv6Internet;
          require_dnssec = true;
          require_nolog = false;
          require_nofilter = true;
          # query_log.file = "/var/log/dnscrypt-proxy/query.log";
          blocked_names.blocked_names_file = blocklist_txt;
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
            # "cloudflare-ipv6"
            # "google"
            # "google-ipv6"
          ];
        };
      };
      systemd.services.dnscrypt-proxy.serviceConfig.StateDirectory = StateDirectory;
    };
}
