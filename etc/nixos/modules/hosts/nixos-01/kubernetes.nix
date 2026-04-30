# INFO: https://wiki.nixos.org/wiki/Kubernetes
# INFO: https://nixos.org/manual/nixos/stable/#sec-kubernetes
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-01-kubernetes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # When using 'easyCerts = true;', the IP address must resolve to the master at the time of creation.
      # In this case, set 'kubeMasterIP = "127.0.0.1";'. Otherwise, you may encounter the following issue: https://github.com/NixOS/nixpkgs/issues/59364.
      kubeMasterIP = "100.69.10.63";
      kubeMasterHostname = "nixos-01";
      kubeMasterAPIServerPort = 6443;
      # cniBinDir = "/var/lib/kubernetes/bin";
      cniBinDir = config.services.kubernetes.dataDir + "/bin";
      my-kubernetes-helm =
        with pkgs;
        wrapHelm kubernetes-helm {
          plugins = with pkgs.kubernetes-helmPlugins; [
            helm-secrets
            helm-diff
            helm-s3
            helm-git
          ];
        };
      my-helmfile = pkgs.helmfile-wrapped.override {
        inherit (my-kubernetes-helm) pluginsDir;
      };
    in
    {
      environment.etc = {
        "k8s".source = ../../../../../k8s;
      };
      # virtualisation.docker = {
      #   enable = true;
      #   # enableNvidia = true;
      #   # extraOptions = "--default-runtime=nvidia";
      # };
      boot.kernelModules = [ "ceph" ];
      networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
      networking.firewall = {
        trustedInterfaces = [
          "cilium_net"
          "cilium_host"
        ];
        allowedUDPPorts = [
          # dns
          10053 # config.services.kubernetes.addons.dns.ports.dns
          # cilium
          4240
          8472
        ];
        allowedTCPPorts = [
          config.services.kubernetes.apiserver.securePort
          # dns
          10054
          10055
          # cilium
          9879
          4244
          9965
          9964
          9234
          9963
        ];
      };
      environment.systemPackages =
        with pkgs;
        [
          # kompose
          kubectl
          kubernetes
        ]
        ++ [
          my-kubernetes-helm # helm
          my-helmfile # helmfile
        ];
      virtualisation = {
        containerd = {
          enable = true;
          settings.plugins."io.containerd.grpc.v1.cri".cni = {
            bin_dir = cniBinDir;
          };
        };
      };
      systemd.tmpfiles.rules = [
        "d /var/lib/kubernetes/bin 0755 root root -"
      ];
      services.kubernetes = {
        package = pkgs.unstable.kubernetes;
        # package = pkgs.kubernetes;
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
        addons.dns = {
          enable = true;
          replicas = 1;
        };
        proxy.enable = false;
        flannel.enable = false;
        kubelet = {
          cni.packages = lib.mkForce [ ];
          extraOpts = builtins.concatStringsSep " " [
            "--root-dir=/var/lib/kubelet"
            "--fail-swap-on=false"
          ];
        };
        apiserver = {
          extraOpts = builtins.concatStringsSep " " [
            "--allow-privileged=true"
          ];
        };
      };
      systemd.services.cilium-bootstrap = {
        # enable = false;
        description = "Deploy Cilium CNI, kube-proxy, DNS, etc replacement";
        after = [ "kubernetes.target" ];
        requires = [ "kubernetes.target" ];
        unitConfig = {
          StartLimitIntervalSec = 0;
        };
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
          # StartLimitInterval = 0;
          Slice = "kubernetes.slice";
          # User = "kubernetes";
          # Group = "kubernetes";
        };
        environment = {
          KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";
          K8S_SERVICE_HOST = "${kubeMasterIP}";
          K8S_SERVICE_PORT = "${toString kubeMasterAPIServerPort}";
          HELM_CACHE_HOME = "/tmp/helm/.cache";
          HELM_CONFIG_HOME = "/tmp/helm/.config";
        };
        script = ''
          set -e
          echo "Running Cilium bootstrap script..."

          # solve for this addition to PATH
          export PATH=$PATH:/run/current-system/sw/bin

          # Wait for API server to be ready
          until ${pkgs.kubectl}/bin/kubectl cluster-info; do
            echo "Waiting for Kubernetes API server..."
            sleep 5
          done

          # Check if Cilium is already installed
          # if ${pkgs.kubectl}/bin/kubectl get namespace cilium; then
          #   echo "Cilium namespace already exists, skipping installation"
          #   exit 0
          # fi

          # Deploy Cilium using helmfile
          cd /etc/k8s/cilium/
          ${my-helmfile}/bin/helmfile apply

          echo "Cilium deployed successfully (apparently...)"
        '';
      };
    };
}
