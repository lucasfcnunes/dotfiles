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
    };
}
