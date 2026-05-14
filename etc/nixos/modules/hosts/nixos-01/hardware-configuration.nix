{
  self,
  ...
}:
{
  flake.nixosModules.nixos-01-hardware =
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
