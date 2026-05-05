# INFO: https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
# INFO: https://github.com/nix-community/nixos-vscode-server
{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.vscode-server =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.vscode-server.nixosModules.default
      ];
      services.vscode-server.enable = true;
      environment.systemPackages = [
        pkgs.wget
      ];
      programs.nix-ld.enable = true;
      # vscode-remote-workaround.enable = true; # ! this repo is archived :(
    };
}
