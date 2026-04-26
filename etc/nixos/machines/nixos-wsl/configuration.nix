{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    # ./disko-config.nix
    ../common/sops.nix
  ];
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 6d";
    };
  };
  # networking.networkmanager.enable = true;
  networking.hostName = "nixos-wsl";
  # boot.loader.grub.enable = true;
  boot.kernelModules = [
    "nvme-fabrics"
    "nvme-tcp"
  ];
  environment.variables.PATH = [ "/home/lucasfcnunes/.dotbins/linux/amd64/bin" ];
  environment.systemPackages = with pkgs; [
    nix-ld # https://github.com/nix-community/nix-ld
    nixfmt
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
  ];
  programs = {
    nix-ld.enable = true;
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
  users.users.lucasfcnunes.shell = pkgs.zsh;
  # users.defaultUserShell = pkgs.zsh;
  # system.userActivationScripts.zshrc = "touch .zshrc";
  time.timeZone = "America/Sao_Paulo";
}
