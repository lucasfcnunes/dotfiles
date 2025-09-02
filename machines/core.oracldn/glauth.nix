{
  config,
  pkgs,
  lib,
  ...
}: let
  domain = "ldap.lucasfcnunes.no";

  ui = {
    domain = "directory.lucasfcnunes.no";
    port = 5000;
  };
in {
  imports = [../../modules/glauth-ui.nix];

  users.users.glauth = {
    home = "/var/lib/glauth";
    createHome = true;
    group = "glauth";
    isSystemUser = true;
    isNormalUser = false;
    description = "Glauth LDAP";
    extraGroups = ["acme"];
  };

  users.groups.glauth = {};

  virtualisation.oci-containers.containers.glauth = {
    # image = "glauth/glauth:v2.0.0";
    image = "lucasfcnunes/glauth:v2.0.0-040322-arm64";
    user = config.users.users.glauth.uid;
    # workdir = "/home/podmanager";
    autoStart = true;
    ports = [
      "389:389/tcp"
      "636:636/tcp"
    ];
    environment = {};
    volumes = [
      "glauth-config:/app/config"
      "/var/lib/acme/ldap.lucasfcnunes.no:/certs"
    ];
  };

  # virtualisation.oci-containers.containers.glauth-ui = {
  #   image = "lucasfcnunes/glauth-ui:040322-2-arm64";
  #   user = config.users.users.glauth.uid;
  #   # workdir = " /home/podmanager ";
  #   autoStart = true;
  #   ports = [
  #     "${toString ui.port}:5000/tcp"
  #   ];
  #   environment = {
  #     SECRET_KEY = "test";
  #     MAIL_SERVER = "smtp.lucasfcnunes.com";
  #     MAIL_PORT = "25";
  #     MAIL_USE_TLS = "0";
  #     MAIL_ADMIN = "directory@lucasfcnunes.no";
  #     DATABASE_URL = "postgresql://glauth@localhost:5432/glauth";
  #   };
  #   volumes = [
  #     "glauth-config:/home/ldap/db"
  #   ];
  # };

  services."glauth-ui" = {
    enable = true;

    cookieSecret = "test";

    mail = {
      server = "smtp.lucasfcnunes.com";
      admin = "directory@lucasfcnunes.no";
    };
  };

  security.acme.certs."${domain}" = {
    domain = domain;
    reloadServices = ["docker-glauth.service"];
  };

  security.acme.certs."${ui.domain}".domain = ui.domain;

  services.nginx.virtualHosts."${ui.domain}" = {
    forceSSL = true;
    useACMEHost = ui.domain;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.glauth-ui.port}";
      proxyWebsockets = true;
    };
    extraConfig = ''
      access_log /var/log/nginx/${ui.domain}.access.log;
    '';
  };
}
