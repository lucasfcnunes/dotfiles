# INFO: https://wiki.nixos.org/wiki/Tailscale
# INFO: https://search.nixos.org/options?show=services.tailscale
{ config, pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    # authKeyFile = "${config.sops.secrets."...".path}";
    # useRoutingFeatures = "client";
    # extraSetFlags = [ "--netfilter-mode=nodivert" ];
  };
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  # Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];
  # Optimization: Prevent systemd from waiting for network online
  # (Optional but recommended for faster boot with VPNs)
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
}
