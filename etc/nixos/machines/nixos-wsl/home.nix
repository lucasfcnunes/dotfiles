{ config, pkgs, ... }:
{
  home = {
    stateVersion = "25.05";
    username = "nixos";
    homeDirectory = "/home/nixos";
    packages = with pkgs; [
      git
      gh # github cli
    ];
  };
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Lucas Fernando Cardoso Nunes";
      userEmail = "lucasfc.nunes@gmail.com";
    };
    gh = {
      enable = true;
      settings.editor = "hx";
    };
  };
}
