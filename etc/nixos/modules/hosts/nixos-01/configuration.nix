{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-01-configuration =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.nix-defaults
        self.nixosModules.nixos-01-hardware
        self.nixosModules.nixpkgs-unstable
        self.nixosModules.nixos-01-disko-config
        self.nixosModules.sops
        self.nixosModules.disable-ipv6
        self.nixosModules.use-nftables
        self.nixosModules.net-tools
        self.nixosModules.dns-defaults
        self.nixosModules.users-defaults
        self.nixosModules.nixos-01-kubernetes
        # self.nixosModules.nixos-01-k3s
        self.nixosModules.tailscale
        self.nixosModules.cloudflared
        self.nixosModules.vscode-server
      ];
      networking.hostName = "nixos-01"; # Define your hostname.
      time.timeZone = "UTC";
      networking.networkmanager.enable = true;
      networking.firewall.enable = false; # ! turn it on after configuring it properly
      services.openssh.enable = true;
      # users.defaultUserShell = pkgs.zsh;
      environment.systemPackages = with pkgs; [
        # zsh
        vim
        wget
        # yq
        git
      ];
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    };
}
