{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.disable-ipv6 =
    {
      ...
    }:
    {
      networking.enableIPv6 = false;
      # because NIC tries to acquire IPv6 addresses at boot
      boot.kernelParams = [ "ipv6.disable=1" ];
    };
}
