{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    nixos-wsl = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        self.nixosModules.nixos-wsl-configuration
      ];
    };
  };
}
