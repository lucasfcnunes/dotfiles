{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.xrdp =
    {
      lib,
      pkgs,
      ...
    }:
    {
      services.xrdp = {
        enable = true;
        audio.enable = lib.mkDefault false;
        # defaultWindowManager = lib.mkDefault "${pkgs.i3}/bin/i3";
      };
    };
}
