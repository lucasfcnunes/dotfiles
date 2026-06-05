{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-wsl-configuration =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.nix-defaults
        self.nixosModules.nixos-wsl-hardware
        self.nixosModules.nixos-wsl
        # self.nixosModules.nixos-wsl-disko-config
        self.nixosModules.sops
        self.nixosModules.net-tools
        # self.nixosModules.users-defaults
        self.nixosModules.vscode-server
        self.nixosModules.cross-emulation
        self.nixosModules.home-manager
        self.nixosModules.lucasfcnunes-hm
      ];
      networking.hostName = "nixos-wsl";
      time.timeZone = "America/Sao_Paulo";
      home-manager.users.lucasfcnunes.npiperelay-wsl.enable = true;
      # system.userActivationScripts.zshrc = "touch .zshrc";
      # networking.networkmanager.enable = true;
      services.openssh.enable = false;
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
        # fish
        # starship # prompt
        # fzf # fuzzy finder
        # helix
        # zellij # terminal multiplexer
        # lazygit # git tui
        # jq # json processor
        # yq # jq on steroids processor
        # ripgrep # search tool
        # bat # cat replacement
        # fd # find replacement
        # eza # ls replacement
        # go-task
        # sops
        # age
        kubectl # TODO: dotbins feature https://github.com/basnijholt/dotbins/issues/171
        # kubernetes-helm
        # helmfile
        # k9s
        clickhouse # TODO: make dotbins version
        sqlite-interactive # TODO: make dotbins version
      ];
      programs = {
        # starship = {
        #   enable = true;
        # };
        # fish = {
        #   enable = true;
        #   interactiveShellInit = ''
        #     set fish_greeting ""
        #     starship init fish | source
        #     fzf --fish | source
        #   '';
        # };
        zsh = {
          enable = true;
        };
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
      # boot.loader.grub.enable = true;
      boot.kernelModules = [
        "nvme-fabrics"
        "nvme-tcp"
      ];
    };
}
