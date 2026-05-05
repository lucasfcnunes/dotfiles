{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.std-compliance =
    {
      ...
    }:
    {
      # INFO: https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=137870
      # INFO: https://serverfault.com/questions/17118/how-do-i-set-the-date-format-to-iso-globally-in-linux
      i18n.defaultLocale = "en_US.UTF-8";
      # i18n.extraLocales = [ "en_US.UTF-8/UTF-8" ];
      i18n.extraLocaleSettings = {
        # LC_ALL = "en_US.UTF-8"; # This overrides all other LC_* settings.
        LC_CTYPE = "en_US.UTF8";
        LC_ADDRESS = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MESSAGES = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_DK.UTF-8"; # ISO-8601
        LC_COLLATE = "en_US.UTF-8";
      };
    };
}
