# INFO: https://wiki.nixos.org/wiki/Kubernetes
# INFO: https://nixos.org/manual/nixos/stable/#sec-kubernetes
{ config, pkgs, ... }:
let
  # When using 'easyCerts = true;', the IP address must resolve to the master at the time of creation.
  # In this case, set 'kubeMasterIP = "127.0.0.1";'. Otherwise, you may encounter the following issue: https://github.com/NixOS/nixpkgs/issues/59364.
  kubeMasterIP = "100.69.10.63";
  kubeMasterHostname = "nixos-01";
  kubeMasterAPIServerPort = 6443;
in
{
  virtualisation.docker = {
    enable = true;
    # enableNvidia = true;
    # extraOptions = "--default-runtime=nvidia";
  };
  boot.kernelModules = [ "ceph" ];
  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
  environment.systemPackages = with pkgs; [
    # kompose
    kubectl
    kubernetes
  ];
  services.kubernetes = {
    roles = [
      "master"
      "node"
    ];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    easyCerts = true;
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };
    addons.dns.enable = true;
    kubelet.extraOpts = builtins.concatStringsSep " " [
      "--root-dir=/var/lib/kubelet"
      "--fail-swap-on=false"
    ];
  };
}
