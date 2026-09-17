{
  self,
  inputs,
  ...
}:
{
  # https://wiki.nixos.org/wiki/Libvirt
  flake.nixosModules.libvirt =
    {
      ...
    }:
    {
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;
      users.users.lucasfcnunes = {
        extraGroups = [
          "libvirtd"
          "kvm"
        ];
      };
      # boot.extraModprobeConfig = ''
      #   options kvm_intel nested=1
      # '';
      systemd.network = {
        networks."99-libvirt-ignore" = {
          matchConfig.Name = "virbr* vnet*";
          linkConfig.Unmanaged = "yes";
        };
      };
      networking.nftables = {
        tables.libvirt-forward = {
          family = "inet";
          content = ''
            chain forward {
              type filter hook forward priority filter - 1; policy accept;

              # Allow intra-bridge and inter-VM traffic across virbr interfaces
              iifname "virbr*" oifname "virbr*" accept
              iifname "virbr*" accept
              oifname "virbr*" ct state established,related accept
            }
          '';
        };
      };
      boot.kernel.sysctl = {
        # Allow packet routing between bridge ports
        "net.ipv4.ip_forward" = 1;
        # Disable strict reverse path filtering so inter-bridge traffic isn't dropped
        "net.ipv4.conf.all.rp_filter" = 0;
        "net.ipv4.conf.default.rp_filter" = 0;
      };
      # networking.firewall.extraCommands = ''
      #   # Automatically translated into nftables bytecode by iptables-nft
      #   iptables -t mangle -A POSTROUTING -p udp --dport 68 -j CHECKSUM --checksum-fill 2>/dev/null || true
      # '';
      networking.firewall.checkReversePath = false;
      networking.firewall.trustedInterfaces = [
        "virbr*"
        "vnet*"
      ];
    };
}
