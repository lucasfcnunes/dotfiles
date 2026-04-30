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
        self.nixosModules.nixos-01-kubernetes
        # self.nixosModules.nixos-01-k3s
        self.nixosModules.tailscale
        self.nixosModules.cloudflared
        self.nixosModules.vscode-server
      ];

      # Use the systemd-boot EFI boot loader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "nixos-01"; # Define your hostname.

      # Configure network connections interactively with nmcli or nmtui.
      networking.networkmanager.enable = true;

      # Set your time zone.
      time.timeZone = "UTC";

      # Configure network proxy if necessary
      # networking.proxy.default = "http://user:password@proxy:port/";
      # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      # Select internationalisation properties.
      # i18n.defaultLocale = "en_US.UTF-8";
      # console = {
      #   font = "Lat2-Terminus16";
      #   keyMap = "us";
      #   useXkbConfig = true; # use xkb.options in tty.
      # };

      # Enable the X11 windowing system.
      # services.xserver.enable = true;

      # Configure keymap in X11
      # services.xserver.xkb.layout = "us";
      # services.xserver.xkb.options = "eurosign:e,caps:escape";

      # Enable CUPS to print documents.
      # services.printing.enable = true;

      # Enable sound.
      # services.pulseaudio.enable = true;
      # OR
      # services.pipewire = {
      #   enable = true;
      #   pulse.enable = true;
      # };

      # Enable touchpad support (enabled default in most desktopManager).
      # services.libinput.enable = true;

      security.sudo = {
        # place top level options (like wheelNeedPassword) here
        enable = true; # make sure to enable the sudo package
        execWheelOnly = false;
        wheelNeedsPassword = false;
        extraConfig = "#includedir /etc/sudoers.d"; # write custom config in here
        extraRules = [
          # place sudoers rules here
        ];
      };

      # Define a user account. Don't forget to set a password with ‘passwd’.
      # users.defaultUserShell = pkgs.zsh;
      users.users.root = {
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7I5xIu1oxunktPOmR/HC+EqBJic2z0sbAn+mgluZdLKyDfHkdH/wSiH45jPplkJ473io3OAqJMo+0mgk7gRNSCzc93zj6fbM6JbQa3bC8FJ2uYFYGDkCtgqxgRpTCNcj8bL5inbcfrR3FcZK43ABtCatjqW8y2C39qvpdj0puxa/1Orm2lIxDubYd5oskqKcxUIIPatfFBACr6UXok2zmNDnZtU30f7C6At27nlcii1tNyuGFNVqocLj/qEKTMPp30LHgOewOmOE2u9cb/T39FvGBBJD1z84Xb/47XFREQyi/eBjzI6v5PyJMJ+1IiwI/fgjnxQAnHZqL1htTAcsXhrol5i/Cp08MEo2PkmtWyD3vzwYEMJSxLdghsEQ8ClH2u6QMI2uZIUQpsvNW6uCaH+ooRmcyP3UyspWEVeqSce2I3Iy8mBdCHO0od0Yeqc8P/0B6IfrSUyHXdYetCeRDP5VcpSKsn9/YnjhRW8QSARCV4TvkMwFJpjcZ3eUN3Tb2ix9wEDg9wHXn8nvh4AnfIWAbBffbIWtnT5+JId+h6NhcJlXwQjGRbVctbA6XcAx9AiIml1dr+VHv6hQDwdpEFXy1J58jEnwKJIOJLPp/n6G/7bgyr7H8JhBGIW35ZxzuMvml6amaTWUG2icsFLL/MO+ZuXVJ8JDeUmi0DS8fRw== (none)"
        ];
      };
      users.users.lucasfcnunes = {
        # shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7I5xIu1oxunktPOmR/HC+EqBJic2z0sbAn+mgluZdLKyDfHkdH/wSiH45jPplkJ473io3OAqJMo+0mgk7gRNSCzc93zj6fbM6JbQa3bC8FJ2uYFYGDkCtgqxgRpTCNcj8bL5inbcfrR3FcZK43ABtCatjqW8y2C39qvpdj0puxa/1Orm2lIxDubYd5oskqKcxUIIPatfFBACr6UXok2zmNDnZtU30f7C6At27nlcii1tNyuGFNVqocLj/qEKTMPp30LHgOewOmOE2u9cb/T39FvGBBJD1z84Xb/47XFREQyi/eBjzI6v5PyJMJ+1IiwI/fgjnxQAnHZqL1htTAcsXhrol5i/Cp08MEo2PkmtWyD3vzwYEMJSxLdghsEQ8ClH2u6QMI2uZIUQpsvNW6uCaH+ooRmcyP3UyspWEVeqSce2I3Iy8mBdCHO0od0Yeqc8P/0B6IfrSUyHXdYetCeRDP5VcpSKsn9/YnjhRW8QSARCV4TvkMwFJpjcZ3eUN3Tb2ix9wEDg9wHXn8nvh4AnfIWAbBffbIWtnT5+JId+h6NhcJlXwQjGRbVctbA6XcAx9AiIml1dr+VHv6hQDwdpEFXy1J58jEnwKJIOJLPp/n6G/7bgyr7H8JhBGIW35ZxzuMvml6amaTWUG2icsFLL/MO+ZuXVJ8JDeUmi0DS8fRw== (none)"
        ];
        password = "12345678"; # ! Change this to a secure password or use `passwd` after installation.
        isNormalUser = true;
        extraGroups = [
          "root"
          "wheel"
        ]; # Enable ‘sudo’ for the user.
        # packages = with pkgs; [
        #   tree
        # ];
      };

      # programs = {
      #   zsh.enable = true;
      #   # firefox.enable = true;
      # };

      # List packages installed in system profile.
      # You can use https://search.nixos.org/ to find more packages (and options).
      environment.systemPackages = with pkgs; [
        # zsh
        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        wget
        # yq
        git
      ];

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      # programs.mtr.enable = true;
      # programs.gnupg.agent = {
      #   enable = true;
      #   enableSSHSupport = true;
      # };

      # List services that you want to enable:

      # Enable the OpenSSH daemon.
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      networking.firewall.enable = false;
      # networking.firewall.enable = true;

      # Copy the NixOS configuration file and link it from the resulting system
      # (/run/current-system/configuration.nix). This is useful in case you
      # accidentally delete configuration.nix.
      # system.copySystemConfiguration = true;

      # This option defines the first version of NixOS you have installed on this particular machine,
      # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
      #
      # Most users should NEVER change this value after the initial install, for any reason,
      # even if you've upgraded your system to a new NixOS release.
      #
      # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
      # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
      # to actually do that.
      #
      # This value being lower than the current NixOS release does NOT mean your system is
      # out of date, out of support, or vulnerable.
      #
      # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
      # and migrated your data accordingly.
      #
      # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    };
}
