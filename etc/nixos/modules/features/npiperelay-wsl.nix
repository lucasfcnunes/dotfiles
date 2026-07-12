{
  self,
  inputs,
  ...
}:
{
  flake.homeModules.npiperelay-wsl =
    # INFO: inspired by
    # https://sxda.io/posts/sharing-ssh-agent-wsl
    # https://github.com/demonbane/wsl-gpg-systemd
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options = {
        npiperelay-wsl.enable = lib.mkEnableOption "Enable npiperelay sockets for WSL";
      };
      config = lib.mkIf config.npiperelay-wsl.enable {
        home.sessionVariables = {
          SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh/openssh-ssh-agent.sock";
          # TODO: below line can't possibly work because of https://github.com/albertony/npiperelay/issues/78
          # SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
        };
        systemd.user =
          let
            writeScriptFunction =
              hostSocketPath:
              let
                name = hostSocketPath |> lib.match "^.*[/\\](.+?)$" |> lib.head;
                isGpgAgent = hostSocketPath |> lib.hasInfix "gpg-agent";
                isNamedPipe = hostSocketPath |> lib.hasInfix "pipe";
                isSsh = hostSocketPath |> lib.hasInfix "ssh";
                flags =
                  (
                    [
                      "-v"
                      # "-p"
                      # "-l"
                      # "-ep"
                      "-ei"
                      "-s"
                      # "-a"
                    ]
                    ++ (
                      if isGpgAgent then
                        [
                          "-p"
                          "-l"
                          "-ep"
                          "-a"
                        ]
                      else
                        [ ]
                    )
                    ++ (if isSsh then [ ] else [ ])
                    ++ (if isNamedPipe then [ ] else [ ])
                  )
                  |> lib.lists.unique
                  |> lib.concatStringsSep " ";
              in
              pkgs.writeScript "${name}.sh" ''
                #!/bin/sh
                set -euo pipefail
                log_info() { printf "[INFO] %s\n" "$*" >&2; }
                PATH="$PATH:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/"
                log_info "starting npiperelay..."
                _HOST_SOCKET_PATH=$(powershell.exe -NoProfile -Command 'Write-Host -NoNewLine ${hostSocketPath}' < /dev/null)
                log_info "mapping $_HOST_SOCKET_PATH -> $XDG_RUNTIME_DIR/gnupg/<socket_name>"
                log_info "PATH=$PATH"
                log_info "flags=${flags}"
                exec ${lib.getExe pkgs.pkgsCross.mingwW64.windows.npiperelay} ${flags} $_HOST_SOCKET_PATH
              '';
          in
          {
            sockets = {
              gpg-agent = {
                Unit = {
                  Description = "GnuPG cryptographic agent and passphrase cache";
                  Documentation = [
                    "man:gpg-agent(1)"
                  ];
                };
                Install = {
                  WantedBy = [
                    "sockets.target"
                  ];
                };
                Socket = {
                  ListenStream = "%t/gnupg/S.gpg-agent";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
              };
              gpg-agent-ssh = {
                Unit = {
                  Description = "GnuPG cryptographic agent (ssh-agent emulation)";
                  Documentation = [
                    "man:gpg-agent(1)"
                    "man:ssh-add(1)"
                    "man:ssh-agent(1)"
                    "man:ssh(1)"
                  ];
                };
                Install = {
                  WantedBy = [
                    "sockets.target"
                  ];
                };
                Socket = {
                  # ListenStream = "%t/gnupg/S.gpg-agent.ssh";
                  ListenStream = "%t/ssh/openssh-ssh-agent.sock";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
              };
            };
            services = {
              "gpg-agent@" = {
                Unit = {
                  Description = "gpg4win to WSL connector for GPG (%I)";
                  # Requires = [
                  #   "gpg-agent.socket"
                  # ];
                  PartOf = [
                    "gpg-agent.socket"
                  ];
                };
                # Install = {
                #   WantedBy = [
                #     "default.target"
                #   ];
                # };
                Service = {
                  Type = "simple";
                  # ExecStartPre = "'/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe' -NoProfile -Command 'gpgconf.exe --launch gpg-agent'";
                  # ExecStart = writeScriptFunction ''$(gpgconf.exe --list-dir agent-extra-socket)'';
                  ExecStart = writeScriptFunction ''$env:LOCALAPPDATA\gnupg\S.gpg-agent.extra'';
                  StandardInput = "socket";
                  StandardOutput = "socket";
                  StandardError = "journal";
                  Sockets = [
                    "gpg-agent.socket"
                  ];
                  # Restart = "on-failure";
                };
              };
              "gpg-agent-ssh@" = {
                Unit = {
                  Description = "gpg4win to WSL connector for SSH (%I)";
                  # Requires = [
                  #   "gpg-agent-ssh.socket"
                  # ];
                  PartOf = [
                    "gpg-agent-ssh.socket"
                  ];
                };
                # Install = {
                #   WantedBy = [
                #     "default.target"
                #   ];
                # };
                Service = {
                  Type = "simple";
                  # ExecStart = writeScriptFunction ''$env:LOCALAPPDATA\gnupg\S.gpg-agent.ssh'';
                  # ExecStart = writeScriptFunction ''$(gpgconf.exe --list-dir agent-ssh-socket)'';
                  ExecStart = writeScriptFunction ''\\.\pipe\openssh-ssh-agent'';
                  StandardInput = "socket";
                  StandardOutput = "socket";
                  StandardError = "journal";
                  Sockets = [
                    "gpg-agent-ssh.socket"
                  ];
                  # Restart = "on-failure";
                };
              };
            };
          };
        # TODO: https://marc.info/?l=gnupg-users&m=175801341607146
        # TODO: https://github.com/nix-community/home-manager/issues/6067
        home.file."${config.programs.gpg.homedir}/common.conf".text = ''
          # use-keyboxd
        '';
        programs.gpg = {
          enable = true;
          settings = {
            no-autostart = true;
          };
        };
      };
    };
}
