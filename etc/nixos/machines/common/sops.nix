{
  # pkgs,
  # config,
  ...
}:
{
  sops = {
    defaultSopsFile = ../../../../.sops.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # age.keyFile = "/persist/sops/age/keys.txt";
    # age.generateKey = true;
  };
}
