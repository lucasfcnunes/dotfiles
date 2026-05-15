{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    nixos-01 = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.nixos-01-configuration
      ];
    };
  };
}
