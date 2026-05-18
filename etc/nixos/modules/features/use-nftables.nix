{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.use-nftables =
    {
      lib,
      pkgs,
      ...
    }:
    let
      blacklistedKernelModules = [
        # legacy ipv4
        "ip_tables"
        "iptable_filter"
        "iptable_mangle"
        "iptable_nat"
        "iptable_raw"
        # legacy ipv6
        "ip6_tables"
        "ip6table_filter"
        "ip6table_mangle"
        "ip6table_nat"
        "ip6table_raw"
        # common infra
        "br_netfilter"
        "x_tables"
      ];
      extraModprobeConfig = lib.concatMapStringsSep "\n" (
        kmod: "install ${kmod} ${pkgs.coreutils}/bin/false"
      ) blacklistedKernelModules;
    in
    {
      networking.firewall.enable = lib.mkDefault true;
      networking.firewall.checkReversePath = lib.mkDefault "loose";
      networking.nftables.enable = true;
      environment.systemPackages = with pkgs; [
        nftables
        iptables # (actually) iptables-nft
        # iptables-legacy
      ];
      boot.blacklistedKernelModules = blacklistedKernelModules;
      boot.extraModprobeConfig = extraModprobeConfig;
    };
}
