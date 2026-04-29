{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixpkgs-unstable =
    {
      ...
    }:
    let
      overlay-pkgs-unstable = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit (final) config;
          inherit (final.stdenv.hostPlatform) system;
        };
      };
    in
    {
      imports = [
        { nixpkgs.overlays = [ overlay-pkgs-unstable ]; }
      ];
    };
}
