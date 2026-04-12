{
  services.cloudflared = {
    enable = true;
    # tunnels = {
    #   "00000000-0000-0000-0000-000000000000" = {
    #     credentialsFile = "${config.sops.secrets.cloudflared-creds.path}";
    #     default = "http_status:404";
    #     ingress = {
    #       "*.lucasfcnunes.com" = {
    #         service = "http://localhost:80";
    #         path = "/*.(jpg|png|css|js)";
    #       };
    #       "*.keluyu.com" = "http://localhost:80";
    #     };
    #   };
    # };
  };
  # services.openssh.settings.Macs = [
  #   # Current defaults:
  #   "hmac-sha2-512-etm@openssh.com"
  #   "hmac-sha2-256-etm@openssh.com"
  #   "umac-128-etm@openssh.com"
  #   # Added:
  #   "hmac-sha2-256"
  # ];
}
