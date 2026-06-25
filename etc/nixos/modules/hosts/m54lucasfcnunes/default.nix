{
  self,
  inputs,
  ...
}:
{
  # flake.nixosConfigurations = {
  #   m54lucasfcnunes = inputs.nixpkgs.lib.nixosSystem {
  #     modules = [
  #       self.nixosModules.m54lucasfcnunes-configuration
  #     ];
  #   };
  # };
  flake.nixOnDroidConfigurations = {
    m54lucasfcnunes = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import inputs.nixpkgs { system = "aarch64-linux"; };
      modules = [
        self.nixOnDroidModules.m54lucasfcnunes-configuration
      ];
    };
  };
}
