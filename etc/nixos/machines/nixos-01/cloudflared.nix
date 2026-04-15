{
  # pkgs,
  config,
  ...
}:
{
  sops.secrets = {
    "ee20eb8e-3e08-438c-92b8-cce52683ae19.json" = {
      sopsFile = ../../secrets/cloudflared.enc.yaml;
    };
  };
  services.cloudflared = {
    enable = true;
    tunnels = {
      "ee20eb8e-3e08-438c-92b8-cce52683ae19" = {
        credentialsFile = "${config.sops.secrets."ee20eb8e-3e08-438c-92b8-cce52683ae19.json".path}";
        default = "http_status:404";
        ingress = {
          "*.lucasfcnunes.com" = {
            service = "http://localhost:80";
            path = "/*.(jpg|png|css|js)";
          };
          "*.keluyu.com" = "http://localhost:80";
        };
      };
    };
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
