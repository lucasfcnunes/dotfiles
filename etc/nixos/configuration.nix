{ config, lib, pkgs, ... }:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 6d";
    };
  };
  boot.kernelModules = [ "nvme-fabrics" "nvme-tcp" ];
  environment.systemPackages = with pkgs; [
    nix-ld-rs # https://github.com/nix-community/nix-ld
    starship # prompt
    fish # shell
    direnv # environment variable manager
    fzf # fuzzy finder
    vim
    helix
    curl
    wget
    zellij # terminal multiplexer
    lazygit # git tui
    jq # json processor
    ripgrep # search tool
    bat # cat replacement
    fd # find replacement
    eza # ls replacement
    git # version control
  ];
  programs = {
    nix-ld.enable = true;
    starship = {
      enable = true;
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting ""
        starship init fish | source
        fzf --fish | source
      '';
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
  users.users.nixos.shell = pkgs.fish;
}
