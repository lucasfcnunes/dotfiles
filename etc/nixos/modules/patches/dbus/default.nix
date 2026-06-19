{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.dbus-patch =
    {
      pkgs,
      ...
    }:
    {
      services.dbus = {
        brokerPackage = pkgs.dbus-broker.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./dbus-broker-logging.patch
          ];
        });
      };
    };
}
