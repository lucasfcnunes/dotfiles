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
      nix.nixPath = [
        "nixos-wsl=${inputs.nixos-wsl}"
      ];
      wsl.enable = true;
      wsl.docker-desktop.enable = true;
      wsl.defaultUser = "lucasfcnunes";
    };
}
