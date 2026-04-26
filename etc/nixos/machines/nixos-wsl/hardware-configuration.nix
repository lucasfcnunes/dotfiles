{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ ];
  hardware.facter.reportPath = ./facter.json;
}
