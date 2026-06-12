{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.fonts =
    {
      pkgs,
      ...
    }:
    {
      fonts.packages = with pkgs; [
        # nerd-fonts.droid-sans-mono
        # nerd-fonts.fira-code
        # nerd-fonts.hack
        nerd-fonts.roboto
        nerd-fonts.roboto-mono
        nerd-fonts.roboto-serif
      ];
    };
}
