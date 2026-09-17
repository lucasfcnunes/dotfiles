{
  self,
  inputs,
  ...
}:
{
  # https://wiki.nixos.org/wiki/VirtualBox
  flake.nixosModules.virtualbox =
    {
      ...
    }:
    {
      virtualisation.virtualbox.host.enable = true;
      virtualisation.virtualbox.host.enableKvm = true;
      # virtualisation.virtualbox.host.enableExtensionPack = true; # unfree
      users.users.lucasfcnunes = {
        extraGroups = [ "vboxusers" ];
      };
      # virtualisation.virtualbox.guest.enable = true;
      # virtualisation.virtualbox.guest.dragAndDrop = true;
      virtualisation.virtualbox.host.addNetworkInterface = false;
    };
}
