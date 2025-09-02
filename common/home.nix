{
  config,
  pkgs,
  lib,
  ...
}: {
  environment.homeBinInPath = true;
  home-manager = {
    verbose = true;
    backupFileExtension = "hm_bak~";
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      lucasfcnunes = {
        imports = [
          ../home
        ];
        programs.git = {
          extraConfig = {
            user = {
              signingkey = lib.mkForce "/home/lucasfcnunes/.ssh/id_ed25519.pub";
            };
          };
        };
      };
      # root = {
      #   imports = [
      #     ../home
      #   ];
      # };
    };
  };
}
