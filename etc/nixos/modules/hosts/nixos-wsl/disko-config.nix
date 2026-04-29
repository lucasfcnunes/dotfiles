{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-wsl-disko-config =
    {
      lib,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];
      # WSL doesn't have a real disk, so we don't need to configure one.
    };
}
