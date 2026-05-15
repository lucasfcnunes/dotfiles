{
  self,
  inputs,
  ...
}:
let
  genericPkgs =
    system: overlays:
    import inputs.nixpkgs {
      inherit system;
      inherit overlays;
    };
  genericDeployPkgs =
    system:
    genericPkgs system [
      # inputs.deploy-rs.overlay
      inputs.deploy-rs.overlays.default
      # TODO: use wrapper-modules instead of overlay to inject deploy-rs into packages (?)
      # TODO: make a flake.overlays.deploy-rs
      (final: prev: {
        deploy-rs = {
          inherit (genericPkgs system [ ]) deploy-rs;
          inherit (prev.deploy-rs) lib;
        };
      })
    ];
in
{
  perSystem =
    {
      system,
      ...
    }:
    {
      checks = (genericDeployPkgs system).deploy-rs.lib.deployChecks self.deploy;
    };
  flake.deploy.nodes = builtins.mapAttrs (
    name: nixosConfiguration:
    let
      # TODO: solve for host with no facter.reportPath set case too
      system = nixosConfiguration.config.hardware.facter.report.system;
      hostname = nixosConfiguration.config.networking.hostName;
      deployPkgs = genericDeployPkgs system;
    in
    {
      inherit hostname;
      sshUser = "lucasfcnunes";
      user = "root";
      autoRollback = false;
      magicRollback = false;
      # remoteBuild = true;
      activationTimeout = 600;
      confirmTimeout = 60;
      sshOpts = [
        "-oControlMaster=no"
      ];
      profiles.system.path = deployPkgs.deploy-rs.lib.activate.nixos nixosConfiguration;
    }
  ) self.nixosConfigurations;
}
