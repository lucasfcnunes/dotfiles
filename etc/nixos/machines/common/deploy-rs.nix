{
  self,
  inputs,
  ...
}:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs { inherit system; };
  deployPkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      # inputs.deploy-rs.overlay
      inputs.deploy-rs.overlays.default
      (self: super: {
        deploy-rs = {
          inherit (pkgs) deploy-rs;
          lib = super.deploy-rs.lib;
        };
      })
    ];
  };
in
{
  flake.checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
  flake.deploy.nodes = {
    nixos-wsl = {
      hostname = "nixos-wsl";
      profiles.system = {
        user = "lucasfcnunes";
        # path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixos-wsl;
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.nixos-wsl;
      };
    };
    nixos-01 = {
      hostname = "nixos-01";
      # hostname = "nixos-01.tail3404eb.ts.net";
      sshUser = "lucasfcnunes";
      # interactiveSudo = true;
      profiles.system = {
        user = "root";
        autoRollback = false;
        magicRollback = false;
        # remoteBuild = true;
        activationTimeout = 600;
        confirmTimeout = 60;
        # path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixos-01;
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.nixos-01;
      };
    };
  };
}
