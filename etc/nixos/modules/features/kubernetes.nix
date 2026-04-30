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
      kubeMasterIP = "100.69.10.63"; # TODO: make this configurable
      kubeMasterHostname = "nixos-01"; # TODO: make this configurable
      kubeMasterAPIServerPort = 6443; # TODO: make this configurable
      kubeMasterUrl = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
      # kubeConfigFile = "/etc/kubernetes/cluster-admin.kubeconfig";
      # kubeConfigFile = config.environment.etc."kubernetes/cluster-admin.kubeconfig".source;
      kubeConfigFile =
        config.environment.etc.${config.services.kubernetes.pki.etcClusterAdminKubeconfig}.source;
      kubeRoles = [
        # TODO: make this configurable
        "master"
        "node"
      ];
      # cniBinDir = "/var/lib/kubernetes/bin";
      cniBinDir = config.services.kubernetes.dataDir + "/bin";
    in
    {
      imports = [
        self.nixosModules.helmfile
      ];
      environment.etc = {
        "k8s".source = ../../../../k8s;
      };
      environment.variables = {
        KUBECONFIG = kubeConfigFile;
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
      environment.systemPackages = with pkgs.unstable; [
        # kompose
        kubectl
        kubernetes
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
        roles = kubeRoles;
        masterAddress = kubeMasterHostname;
        apiserverAddress = kubeMasterUrl;
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
          # kubeconfig.server = kubeMasterUrl; #TODO: set this only for worker nodes
          cni.packages = lib.mkForce [ ];
          extraOpts = builtins.concatStringsSep " " [
            "--root-dir=/var/lib/kubelet"
            # "--fail-swap-on=false"
          ];
        };
        apiserver = {
          extraOpts = builtins.concatStringsSep " " [
            "--allow-privileged=true"
          ];
        };
      };
      systemd.services.cilium-bootstrap = {
        # enable = false; # TODO: enable this only on nixos-01
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
        path =
          [ ]
          ++ (with pkgs.unstable; [
            kubectl
          ])
          ++ (with self.packages.${pkgs.system}; [
            my-kubernetes-helm
            my-helmfile
          ]);
        environment = {
          KUBECONFIG = "${kubeConfigFile}";
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
          until kubectl cluster-info; do
            echo "Waiting for Kubernetes API server..."
            sleep 5
          done

          # Check if Cilium is already installed
          # if kubectl get namespace cilium; then
          #   echo "Cilium namespace already exists, skipping installation"
          #   exit 0
          # fi

          # Deploy Cilium using helmfile
          cd /etc/k8s/cilium/
          helmfile apply

          echo "Cilium deployed successfully (apparently...)"
        '';
      };
    };
}
