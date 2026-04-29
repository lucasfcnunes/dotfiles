{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.nixos-01-home-manager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.lucasfcnunes =
        {
          config,
          lib,
          pkgs,
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
        };
    };

}
