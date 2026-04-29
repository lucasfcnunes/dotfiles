{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-wsl-hardware =
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
    };
}
