{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      shellCommon = {
        enable = true;
        profileExtra = lib.mkBefore ''
          if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
            exec uwsm start -S hyprland-uwsm.desktop
            # exec hyprland
          fi
        '';
      };
    in
    {
      services.getty.autologinUser = lib.mkDefault "lucasfcnunes";
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };
      services.displayManager.ly.enable = true;
      environment.systemPackages = with pkgs; [
        foot
        hyprpaper
        kitty
        waybar
        # >>> alternatives
        # rofi
        # thunar
        # swaybg
        # vis
      ];
      home-manager.users.${config.services.getty.autologinUser}.programs = {
        bash = { } // shellCommon;
        zsh = { } // shellCommon;
      };
    };
}
