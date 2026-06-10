{
  self,
  ...
}:
{
  flake.nixosModules.dkplucasfcnunes-hardware =
    {
      ...
    }:
    {
      imports = [
        self.nixosModules.hyper-v-guest
      ];
      hardware.facter.reportPath = ./facter.json;
    };
}
