{
  pkgs,
  lib,
  ...
}: let
  isWorkstation = pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64;
  lucasfcnunesLogin = hostname: {
    hostname = hostname;
    user = "lucasfcnunes";
    port = 22;
  };
  fapRoot = {
    hostname = "%h.lucasfcnunes.com";
    user = "root";
    port = 22;
  };
in {
  home.sessionVariables = lib.mkIf isWorkstation {
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  programs.ssh = {
    enable = true;
    forwardAgent = isWorkstation;
    extraConfig =
      if isWorkstation
      then ''
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      ''
      else "";

    matchBlocks = {
      "sprocket" = lucasfcnunesLogin "sprocket.nvg.ntnu.no";
      "devl" = lucasfcnunesLogin "dev.ldn.lucasfcnunes.com";
      "devf" = lucasfcnunesLogin "dev.oracfurt.lucasfcnunes.com";
      "*.s" = {
        hostname = "%handefjordfiber.no";
        user = "root";
        port = 22;
        proxyJump = "core.terra.lucasfcnunes.com";
      };
      "*.terra" = fapRoot;
      "*.tjoda" = fapRoot;
      "*.ldn" = fapRoot;
      "*.oracldn" = fapRoot;
      "*.oracfurt" = fapRoot;

      # Tailscale configuration
      "bunny*" = {
        user = "ubuntu";
      };
      "control*" = {
        user = "ubuntu";
      };
      "lucasfcnunes-workstation*" = {
        user = "ubuntu";
      };
      "tailscale-proxy" = {
        match = "host !bunny.corp.tailscale.com,*.tailscale.com,control,shard*,derp*,trunkd*";
        proxyCommand = "/Users/lucasfcnunes/go/bin/ts-ssh-proxy %r %h %p";
      };
    };
  };
}
