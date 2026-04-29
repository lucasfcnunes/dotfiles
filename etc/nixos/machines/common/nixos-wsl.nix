{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-wsl =
    {
      ...
    }:
    {
      imports = [
        inputs.nixos-wsl.nixosModules.default
      ];
      wsl.enable = true;
      wsl.docker-desktop.enable = true;
      wsl.defaultUser = "lucasfcnunes";
    };
}
