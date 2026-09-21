{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.writable-etc-hosts =
    {
      pkgs,
      ...
    }:
    {
      # INFO: hostctl doesn't work properly with NixOS, so we need to disable immutability on /etc/hosts
      # INFO: we'll always sync /etc/hosts.original to /etc/hosts
      environment.etc.hosts = {
        enable = true;
        # mode = "0644";
        target = "hosts.original";
      };
      systemd.services.update-etc-hosts = {
        script = ''
          touch /etc/hosts
          chmod 0644 /etc/hosts
          ${pkgs.hostctl}/bin/hostctl replace hosts.original -f /etc/hosts.original
        '';
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = "!/etc/hosts";
        serviceConfig.Type = "oneshot";
      };
    };
}
