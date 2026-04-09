{
  config,
  pkgs,
  lib,
  ...
}:
{
  home = {
    stateVersion = "25.11";
    username = "lucasfcnunes";
    homeDirectory = "/home/lucasfcnunes";
    packages = with pkgs; [
      git
      zsh
    ];
  };
  programs = {
    home-manager.enable = true;
    zsh = {
      enable = true;
    };
  };
}
