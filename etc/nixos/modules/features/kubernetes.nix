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
      options,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      hasIPv6Enabled = config.networking.enableIPv6;
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
      rookCephEnabled = true;
      kubeResolvConfPath = "kubernetes/resolv.conf";
    in
    {
      imports = [
        self.nixosModules.helmfile
      ];
      environment.etc = {
        "k8s".source = ../../../../k8s;
        "${kubeResolvConfPath}".text = ''
          nameserver ${config.my.dummy-nic.lo-proxy0.ipv4}
          options edns0 trust-ad
        '';
      };
      environment.variables = {
        KUBECONFIG = kubeConfigFile;
      };
      # virtualisation.docker = {
      #   enable = true;
      #   # enableNvidia = true;
      #   # extraOptions = "--default-runtime=nvidia";
      # };
      boot.kernelModules = [
      ]
      ++ (
        if rookCephEnabled then
          [
            "ceph"
            "rbd"
          ]
        else
          [ ]
      );
      networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
      networking.firewall = {
        trustedInterfaces = [
          # "cilium_*"
          "cilium_host"
          "cilium_net"
          # "cilium_vxlan"
          "lxc*"
        ];
        allowedUDPPorts = [
        ];
        allowedTCPPorts = [
          config.services.kubernetes.apiserver.securePort
          config.services.kubernetes.kubelet.port
        ];
      };
      environment.systemPackages =
        with pkgs.unstable;
        [
          # kompose
          kubectl
          kubernetes
        ]
        ++ (
          if rookCephEnabled then
            with pkgs;
            [
              e2fsprogs
              lvm2
              util-linux
              xfsprogs
            ]
          else
            [ ]
        );
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
      ]
      ++ (
        if rookCephEnabled then
          [
            "d /var/lib/rook 0755 root root -"
          ]
        else
          [ ]
      );
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
          corefile =
            let
              corefileOld = options.services.kubernetes.addons.dns.corefile.default;
              corefileNew =
                corefileOld
                |>
                  lib.replaceStrings
                    (
                      [
                        # "forward . /etc/resolv.conf"
                      ]
                      ++ lib.optional (!hasIPv6Enabled) " ip6.arpa"
                    )
                    (
                      [
                        # "forward . ${config.my.dummy-nic.lo-proxy0.ipv4}"
                      ]
                      ++ lib.optional (!hasIPv6Enabled) ""
                    );
            in
            corefileNew;
        };
        proxy.enable = false;
        flannel.enable = false;
        kubelet = {
          # kubeconfig.server = kubeMasterUrl; #TODO: set this only for worker nodes
          cni.packages = lib.mkForce [ ];
          extraOpts = builtins.concatStringsSep " " [
            "--root-dir=/var/lib/kubelet" # TODO: why did i do this? rook-ceph?
            "--resolv-conf=${config.environment.etc."${kubeResolvConfPath}".source}"
            "--authentication-token-webhook=true"
            "--authorization-mode=Webhook"
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
          ++ (with self.packages.${system}; [
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
