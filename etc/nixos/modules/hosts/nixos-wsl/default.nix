{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    nixos-wsl = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.nixos-wsl-configuration
      ];
    };
  };
}
