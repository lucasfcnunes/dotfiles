{
  self,
  ...
}:
{
  flake.nixosModules.aw16lucasfcnunes-hardware =
    {
      ...
    }:
    {
      imports = [
        # self.nixosModules.hyper-v-guest
      ];
      hardware.facter.reportPath = ./facter.json;
    };
}
