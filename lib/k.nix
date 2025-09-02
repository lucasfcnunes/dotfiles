{...}: {
  tailscaleHostname = cfg: builtins.replaceStrings [".lucasfcnunes.com" "."] ["" "-"] cfg.networking.fqdn;
}
