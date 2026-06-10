{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.dkplucasfcnunes-configuration =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.nix-defaults
        self.nixosModules.dkplucasfcnunes-hardware
        self.nixosModules.dkplucasfcnunes-disko-config
        self.nixosModules.boot-defaults
        self.nixosModules.sops
        self.nixosModules.disable-ipv6
        self.nixosModules.use-nftables
        self.nixosModules.net-tools
        self.nixosModules.dns-defaults
        self.nixosModules.users-defaults
        self.nixosModules.tailscale
        self.nixosModules.vscode-server
        self.nixosModules.hyprland
        self.nixosModules.xrdp
        self.nixosModules.home-manager
        self.nixosModules.lucasfcnunes-hm
      ];
      system.stateVersion = "25.11";
      networking.hostId = "efc7412e";
      networking.hostName = "dkplucasfcnunes";
      time.timeZone = "America/Sao_Paulo";
      networking.firewall.enable = true;
      services.openssh.enable = true;
      # users.defaultUserShell = pkgs.zsh;
      environment.systemPackages = with pkgs; [
        git
        gnupg
        curl
        wget
        # vimrm -rf
        neovim
        zsh
        zsh-powerlevel10k
        micromamba
        direnv
        # microsoft-edge
        firefox
      ];
    };
}
