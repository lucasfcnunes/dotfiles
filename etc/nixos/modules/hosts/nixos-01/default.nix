{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    nixos-01 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        self.nixosModules.nixos-01-configuration
      ];
    };
  };
}
