{
  self,
  inputs,
  withSystem,
  ...
}:
{
  flake.overlays.nixpkgs-unstable =
    final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      {
        system,
        ...
      }:
      {
        unstable = import inputs.nixpkgs-unstable {
          inherit (final) config;
          inherit system;
        };
      }
    );

}
