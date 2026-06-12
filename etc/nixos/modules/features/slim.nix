{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.slim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.slim;
    in
    {
      # based on https://github.com/NuschtOS/nixos-modules/blob/32c074f6c3bcb1ed0f7ff7ced4acf99b51abd07a/modules/slim.nix
      options.slim = {
        enable = lib.mkEnableOption "disable some normally rarely used things to slim down the system";
      };
      config = lib.mkIf cfg.enable {
        documentation = {
          doc.enable = false;
          info.enable = false;
        };
        environment.defaultPackages = lib.mkForce [ ];
        programs.thunderbird.package = pkgs.thunderbird.override { cfg.speechSynthesisSupport = false; };
        security.wrapperDirSize = "10M";
        services = {
          orca.enable = false;
          speechd.enable = false;
        };
      };
    };
}
