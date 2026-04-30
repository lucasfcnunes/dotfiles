{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.helmfile =
    {
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with self.packages.${pkgs.system}; [
        my-kubernetes-helm
        my-helmfile
      ];
    };
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:
    {
      # TODO: use wrapper-modules instead of pkgs.wrapHelm and pkgs.helmfile-wrapped.override
      # packages.my-kubernetes-helm = inputs.wrapper-modules.wrappers.kubernetes-helm.wrap {
      #   inherit pkgs;
      #   plugins = with pkgs.kubernetes-helmPlugins; [
      #     helm-secrets
      #     helm-diff
      #     helm-s3
      #     helm-git
      #     # helm-unittest
      #   ];
      # };
      packages.my-kubernetes-helm = pkgs.wrapHelm pkgs.kubernetes-helm {
        plugins = with pkgs.kubernetes-helmPlugins; [
          helm-diff
          helm-git
          helm-s3
          helm-secrets
          # helm-unittest
        ];
      };
      # packages.my-helmfile = inputs.wrapper-modules.wrappers.helmfile-wrapped.wrap {
      #   inherit pkgs;
      #   override = {
      #     inherit (self'.packages.my-kubernetes-helm) pluginsDir;
      #   };
      # };
      packages.my-helmfile = pkgs.helmfile-wrapped.override {
        inherit (self'.packages.my-kubernetes-helm) pluginsDir;
      };
    };
}
