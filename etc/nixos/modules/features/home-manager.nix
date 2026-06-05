{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.home-manager =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.default
      ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };
}
