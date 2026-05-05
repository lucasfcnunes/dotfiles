{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.users-defaults =
    {
      config,
      lib,
      ...
    }:
    {
      security.sudo = {
        enable = true; # make sure to enable the sudo package
        execWheelOnly = false;
        wheelNeedsPassword = false; # ! kinda dangerous, use with caution
        extraConfig = "#includedir /etc/sudoers.d";
        extraRules = [
        ];
      };
      services.openssh = {
        enable = lib.mkDefault false;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
      users.users.root = {
        openssh.authorizedKeys.keys = config.users.users.lucasfcnunes.openssh.authorizedKeys.keys;
      };
      users.users.lucasfcnunes = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlBdpRehqTLYT2XKNJndv0pMWCBuqdLUPCDc1xd2XLp (gpg-ssh-lucasfcnunes)"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7I5xIu1oxunktPOmR/HC+EqBJic2z0sbAn+mgluZdLKyDfHkdH/wSiH45jPplkJ473io3OAqJMo+0mgk7gRNSCzc93zj6fbM6JbQa3bC8FJ2uYFYGDkCtgqxgRpTCNcj8bL5inbcfrR3FcZK43ABtCatjqW8y2C39qvpdj0puxa/1Orm2lIxDubYd5oskqKcxUIIPatfFBACr6UXok2zmNDnZtU30f7C6At27nlcii1tNyuGFNVqocLj/qEKTMPp30LHgOewOmOE2u9cb/T39FvGBBJD1z84Xb/47XFREQyi/eBjzI6v5PyJMJ+1IiwI/fgjnxQAnHZqL1htTAcsXhrol5i/Cp08MEo2PkmtWyD3vzwYEMJSxLdghsEQ8ClH2u6QMI2uZIUQpsvNW6uCaH+ooRmcyP3UyspWEVeqSce2I3Iy8mBdCHO0od0Yeqc8P/0B6IfrSUyHXdYetCeRDP5VcpSKsn9/YnjhRW8QSARCV4TvkMwFJpjcZ3eUN3Tb2ix9wEDg9wHXn8nvh4AnfIWAbBffbIWtnT5+JId+h6NhcJlXwQjGRbVctbA6XcAx9AiIml1dr+VHv6hQDwdpEFXy1J58jEnwKJIOJLPp/n6G/7bgyr7H8JhBGIW35ZxzuMvml6amaTWUG2icsFLL/MO+ZuXVJ8JDeUmi0DS8fRw== (gpg-ssh-lucasfcnunes)"
        ];
        # password = "12345678"; # ! Change this to a secure password or use `passwd` after installation.
        isNormalUser = true;
        extraGroups = [
          "root"
          "wheel"
        ];
      };
    };
}
