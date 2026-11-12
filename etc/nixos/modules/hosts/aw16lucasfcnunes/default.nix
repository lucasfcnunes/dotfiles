{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    aw16lucasfcnunes = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.aw16lucasfcnunes-configuration
      ];
    };
  };
}
