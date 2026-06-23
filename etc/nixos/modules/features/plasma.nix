{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.plasma =
    {
      lib,
      pkgs,
      ...
    }:
    {
      services = {
        desktopManager.plasma6.enable = true;
        displayManager = {
          # autoLogin = {
          #   enable = true;
          #   user = "lucasfcnunes";
          # };
          plasma-login-manager = {
            enable = true;
          };
        };
        pipewire.enable = lib.mkDefault true;
      };
      environment.systemPackages = with pkgs; [
        kdePackages.plasma-workspace
        # KDE Utilities
        kdePackages.discover # Optional: Software center for Flatpaks/firmware updates
        kdePackages.kcalc # Calculator
        kdePackages.kcharselect # Character map
        kdePackages.kclock # Clock app
        kdePackages.kcolorchooser # Color picker
        kdePackages.kolourpaint # Simple paint program
        # kdePackages.krdp
        kdePackages.ksystemlog # System log viewer
        # kdePackages.sddm-kcm # SDDM configuration module
        kdiff3 # File/directory comparison tool
        # Hardware/System Utilities (Optional)
        kdePackages.isoimagewriter # Write hybrid ISOs to USB
        kdePackages.partitionmanager # Disk and partition management
        hardinfo2 # System benchmarks and hardware info
        wayland-utils # Wayland diagnostic tools
        wl-clipboard # Wayland copy/paste support
        vlc # Media player
        remmina
        # microsoft-edge
        firefox
        brave
      ];
      environment.plasma6.excludePackages = with pkgs; [
        kdePackages.elisa # Music player
        kdePackages.kdepim-runtime # Akonadi agents
        kdePackages.kmahjongg
        kdePackages.kmines
        kdePackages.konversation # IRC client
        kdePackages.kpat # Solitaire
        kdePackages.ksudoku
        kdePackages.ktorrent
      ];
      systemd.services.plasmalogin.serviceConfig.KeyringMode = "inherit";
      security.pam.services.plasmalogin-autologin.rules.auth = {
        systemd_loadkey = {
          order = 0;
          control = "optional";
          modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
        };
        plasmalogin = {
          order = 1;
          control = "include";
          modulePath = "plasmalogin";
        };
      };
      services.xrdp = {
        # defaultWindowManager = "startplasma-wayland";
        defaultWindowManager = "startplasma-x11";
        audio.enable = true;
      };
      # environment.systemPackages = with pkgs; [
      #   xclip # Required for clipboard support over X11 RDP sessions
      # ];
      nix.nixPath = [
        "plasma-manager=${inputs.plasma-manager}"
      ];
      home-manager.users.lucasfcnunes =
        {
          ...
        }:
        {
          imports = [
            inputs.plasma-manager.homeModules.plasma-manager
            self.homeModules.plasma
          ];
        };
    };
  flake.homeModules.plasma =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.plasma = {
        enable = true;
        #
        # System Settings (Mimic System Settings GUI order)
        #
        # System Settings > Keyboard > Keyboard
        input.keyboard = {
          numlockOnStartup = "on";
          # options = ["ctrl:nocaps"];
        };
        shortcuts = {
          # System Settings > Keyboard > Shortcuts > KWin
          kwin = {
            "ExposeClassCurrentDesktop" = "Meta+Ctrl+Down";
            "Overview" = "Meta+Ctrl+Up";
          };
        };
        # System Settings > Keyboard > Shortcuts > Plasma Manager
        hotkeys.commands = {
          launch-brave = {
            name = "Launch Brave";
            key = "Meta+Shift+F";
            command = "brave";
          };
        };
        # System Settings > Colors & Themes > Window Decorations
        kwin.titlebarButtons.left = [
          "close"
          "minimize"
          "maximize"
        ];
        # System Settings > Text & Fonts > Fonts
        fonts = {
          fixedWidth = {
            family = "JetBrains Mono";
            pointSize = 10;
          };
          general = {
            family = "Roboto";
            pointSize = 10;
          };
          menu = {
            family = "Roboto";
            pointSize = 10;
          };
          small = {
            family = "Roboto";
            pointSize = 8;
          };
          toolbar = {
            family = "Roboto";
            pointSize = 10;
          };
          windowTitle = {
            family = "Roboto";
            pointSize = 10;
          };
        };
        kwin = {
          # System Settings > Window Management > Desktop Effects > ...
          effects = {
            blur = {
              enable = true;
              noiseStrength = 0;
              strength = 6;
            };
            slideBack.enable = true;
            translucency.enable = true;
            wobblyWindows.enable = true;
          };
          # System Settings > Window Management > Virtual Desktops
          virtualDesktops = {
            number = 2;
            rows = 1;
          };
        };
        # System Settings > Screen Locking > Configure Appearance
        kscreenlocker = {
          appearance = {
            showMediaControls = false;
            wallpaperPictureOfTheDay.provider = "bing";
          };
          # appearance.wallpaper = "${config.wallpaper}";
          # autoLock = false;
          # timeout = 0;
        };
        # System Settings > Session > Desktop Session
        session = {
          general.askForConfirmationOnLogout = false;
          sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
        };
        #
        # KRunner
        #
        krunner = {
          position = "center";
        };
        #
        # Spectacle
        #
        spectacle = {
          # Spectacle > Configure Spectacle > Shortcuts
          shortcuts = {
            captureActiveWindow = "Meta+@";
            captureCurrentMonitor = "Meta+#";
            # captureEntireDesktop = "";
            captureRectangularRegion = "Meta+$";
            # captureWindowUnderCursor = "";
            launchWithoutCapturing = "Meta+%";
          };
        };
        #
        # Configuration Files (Order alphabetically)
        #
        configFile = {
          # System Settings > Search > File Search
          baloofilerc."Basic Settings"."Indexing-Enabled" = false;
          # GUI setting unknown
          # Use detailed view for file picker
          kdeglobals."KFileDialog Settings"."View Style" = "Detail";
          # System Settings > Colors & Themes > Splash Screen
          ksplashrc.KSplash = {
            Engine = "none";
            Theme = "None";
          };
          kwinrc = {
            # System Settings > Window Management > Desktop Effects > Geometry Change
            # Add Geometry Change: System Settings > Window Management > Desktop Effects >
            #   Get New...
            Effect-kwin4_effect_geometry_change."Duration" = 500;
          };
          # Spectacle > Configure Spectacle
          "spectaclerc"."General"."launchAction" = "DoNotTakeScreenshot";
        };
        panels = [
          {
            location = "bottom";
            widgets = [
              "org.kde.plasma.kickoff" # Default widgets, with default config are added like this.
              {
                name = "org.kde.plasma.quicklaunch"; # Non-default widgets are added like this.
                config = {
                  General = {
                    launcherUrls = [
                      "file:///run/current-system/sw/share/applications/org.kde.dolphin.desktop"
                      "file:///run/current-system/sw/share/applications/firefox.desktop"
                    ];
                    maxSectionCount = 2;
                  };
                };
              }
              {
                iconTasks = {
                  # Default widgets with custom configuration are added like this.
                  launchers = [
                    "applications:org.kde.dolphin.desktop"
                    "applications:org.kde.konsole.desktop"
                  ];
                };
              }
              "org.kde.plasma.marginsseparator"
              "org.kde.plasma.systemtray"
              "org.kde.plasma.digitalclock"
            ];
            height = 52;
          }
          # if desired, a second panel can be added here
        ];
      };
    };
}
