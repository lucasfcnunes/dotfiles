{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.net-tools =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        inetutils
        traceroute
        bind
        whois
        mtr
        nmap
        tcpdump
        iperf3
        netcat
      ];
    };
}
