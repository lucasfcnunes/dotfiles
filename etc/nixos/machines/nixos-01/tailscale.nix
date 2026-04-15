{
  services.tailscale = {
    enable = true;
    # authKeyFile = "${config.sops.secrets."...".path}";
    # useRoutingFeatures = "client";
    # extraSetFlags = [ "--netfilter-mode=nodivert" ];
  };
}
