{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-wsl =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.nixos-wsl.nixosModules.default
        self.nixosModules.gpu
      ];
      nix.nixPath = [
        "nixos-wsl=${inputs.nixos-wsl}"
      ];
      wsl.enable = true;
      wsl.docker-desktop.enable = true;
      wsl.defaultUser = "lucasfcnunes"; # TODO: https://github.com/nix-community/NixOS-WSL/discussions/1068
      wsl.interop.register = lib.mkIf (lib.length config.boot.binfmt.emulatedSystems > 0) (
        lib.mkOverride 900 true
      );
      wsl.useWindowsDriver = true;
      # wsl.startMenuLaunchers = false;
      environment.sessionVariables = {
        LD_LIBRARY_PATH = [
          # "/usr/lib/wsl/lib"
          "/run/opengl-driver/lib" # To make WSLg driver available to the apps
        ];
      };
      # programs.nix-ld.libraries = [
      #   "/run/opengl-driver/lib"
      # ];
      virtualisation.hypervGuest.dxgkrnl.enable = false;
    };
}
