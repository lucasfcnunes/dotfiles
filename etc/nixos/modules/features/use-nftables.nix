{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.use-nftables =
    {
      ...
    }:
    {
      networking.nftables.enable = true;
      # disable iptables and related modules
      boot.blacklistedKernelModules = [
        "ip_tables"
        "iptable_nat"
        "iptable_filter"
        "iptable_mangle"
        "iptable_raw"
        "ip6_tables"
        "ip6table_nat"
        "ip6table_filter"
        "ip6table_mangle"
        "ip6table_raw"
        "x_tables"
        "br_netfilter"
      ];
      boot.extraModprobeConfig = ''
        install ip_tables /bin/false
        install iptable_nat /bin/false
        install iptable_filter /bin/false
        install iptable_mangle /bin/false
        install iptable_raw /bin/false
        install ip6_tables /bin/false
        install ip6table_nat /bin/false
        install ip6table_filter /bin/false
        install ip6table_mangle /bin/false
        install ip6table_raw /bin/false
        install x_tables /bin/false
        install br_netfilter /bin/false
      '';
    };
}
