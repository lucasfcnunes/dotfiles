{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.xrdp =
    {
      ...
    }:
    {
      services.xrdp = {
        enable = true;
        audio.enable = false;
        defaultWindowManager = "xterm";
      };
    };
}
