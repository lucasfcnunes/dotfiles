# TODO: add more features and settings, like autologin, display manager, etc
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.hyprland =
    {
      lib,
      pkgs,
      ...
    }:
    {
      # services.getty.autologinUser = lib.mkDefault "lucasfcnunes";
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };
      # services.displayManager.ly.enable = true;
      # environment.systemPackages = with pkgs; [
      #   # kitty
      #   # foot
      #   # hyprpaper
      #   # waybar
      #   # >>> alternatives
      #   # rofi
      #   # thunar
      #   # swaybg
      #   # vis
      # ];
    };
  flake.homeModules.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        xdg.configFile."uwsm/env".source =
          "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
        wayland.windowManager.hyprland = {
          enable = true;
          # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
          package = null;
          portalPackage = null;
          plugins = with pkgs.hyprlandPlugins; [
            hyprbars
            # hy3
          ];
          settings = {
            "$mod" = "SUPER";
            bind = [
              "$mod, F, exec, firefox"
              ", Print, exec, grimblast copy area"
              (
                # workspaces
                # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
                builtins.concatLists (
                  builtins.genList (
                    i:
                    let
                      ws = i + 1;
                    in
                    [
                      "$mod, code:1${toString i}, workspace, ${toString ws}"
                      "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
                    ]
                  ) 9
                )
              )
            ];
          };
        };
        programs.waybar = {
          enable = true;
          systemd.enable = true;
        };
        # INFO: https://terminaltrove.com/terminals
        programs.kitty = {
          enable = true;
        };
        # programs.ghostty.enable = true;
        # programs.alacritty.enable = true;
        services.hyprpaper = {
          enable = true;
        };
      };
    };
}
