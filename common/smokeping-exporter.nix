{
  config,
  lib,
  ...
}: let
  consul = import ./funcs/consul.nix {inherit lib;};
in {
  services.prometheus.exporters.smokeping = {
    enable = true;

    hosts = [
      "core.terra.lucasfcnunes.com"
      "core.oracldn.lucasfcnunes.com"
      "dev.ldn.lucasfcnunes.com"
      "core.tjoda.lucasfcnunes.com"
      # "core.ntnu.lucasfcnunes.com"
      "vg.no"
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  systemd.services."prometheus-smokeping-exporter" = {
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
  };

  my.consulServices.smokeping_exporter = consul.prometheusExporter "smokeping" config.services.prometheus.exporters.smokeping.port;
}
