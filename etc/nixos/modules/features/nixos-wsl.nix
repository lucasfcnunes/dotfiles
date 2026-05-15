{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-wsl =
    {
      config,
      lib,
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
      wsl.interop.register = lib.mkIf (lib.length config.boot.binfmt.emulatedSystems > 0) (
        lib.mkOverride 900 true
      );
    };
}
