{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    dkplucasfcnunes = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.dkplucasfcnunes-configuration
      ];
    };
  };
}
