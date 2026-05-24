# TODO: add a service module for clickhouse, with a systemd unit and configuration file, etc
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.clickhouse =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs.unstable; [
        clickhouse
      ];
    };
}
