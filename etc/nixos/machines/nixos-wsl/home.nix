{
  config,
  pkgs,
  lib,
  ...
}:
{
  home = {
    stateVersion = "25.11";
    username = "lucasfcnunes";
    homeDirectory = "/home/lucasfcnunes";
    packages = with pkgs; [
      git
      gh # github cli
      zsh
    ];
    file = {
      "agents.sh" = {
        executable = true;
        source = ./home/lucasfcnunes/agents.sh;
      };
    };
  };
  systemd.user = {
    sockets = {
      gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
        };
        Socket = {
          ListenStream = "%t/gnupg/S.gpg-agent";
          SocketMode = "0600";
          DirectoryMode = "0700";
          Accept = true;
        };
        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
      gpg-agent-ssh = {
        Unit = {
          Description = "GnuPG cryptographic agent (ssh-agent emulation)";
          Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
        };
        Socket = {
          ListenStream = "%t/gnupg/S.gpg-agent.ssh";
          SocketMode = "0600";
          DirectoryMode = "0700";
          Accept = true;
        };
        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    };
    services = {
      "gpg-agent@" = {
        Unit = {
          Description = "gpg4win to WSL connector for GPG";
          Requires = "gpg-agent.socket";
        };
        Service = {
          Type = "simple";
          ExecStart = "/mnt/c/opt/bin/npiperelay-NZSmartie.exe -ep -ei -s -a 'C:/Users/lucas/AppData/Local/gnupg/S.gpg-agent.extra'";
          # ExecStart = "/mnt/c/opt/bin/npiperelay-NZSmartie.exe -ep -ei -s -a 'C:/Users/lucas/AppData/Local/gnupg/S.gpg-agent'";
          StandardInput = "socket";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      "gpg-agent-ssh@" = {
        Unit = {
          Description = "gpg4win to WSL connector for SSH";
          Requires = "gpg-agent-ssh.socket";
        };
        Service = {
          Type = "simple";
          ExecStart = "/mnt/c/opt/bin/npiperelay-NZSmartie.exe -ei -s '//./pipe/openssh-ssh-agent'";
          StandardInput = "socket";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
  programs = {
    home-manager.enable = true;
    gpg = {
      enable = true;
      publicKeys = [
        {
          source = pkgs.fetchurl {
            url = "https://keybase.io/lucasfcnunes/pgp_keys.asc?fingerprint=51bbb719db9a3f8a928a4d5c9d76b9d8e1e20e99";
            sha256 = "93f1beb2d91b47b78052161316da25169c3920c843974786aea46dba458e89b5";
            # url = "https://github.com/lucasfcnunes.gpg";
            # sha256 = "a12def83439c20a6a36b082a9169596965807f042b2848202075702798cf80b4"; # only trailing newline changed
          };
          trust = 5;
        }
      ];

    };
    zsh = {
      enable = true;
      enableCompletion = true;
      # enableBashCompletion = true;
      # autosuggestions.enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 10000;
      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "dirhistory"
          "history"
        ];
      };
      initContent =
        let
          zshConfigEarlyInit = lib.mkOrder 500 ''
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          '';
          zshConfig = lib.mkOrder 1000 ''
            # --
            POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
            ZSH_THEME="robbyrussell"

            # source $ZSH/oh-my-zsh.sh

            # Preferred editor for local and remote sessions
            if [[ -n $SSH_CONNECTION ]]; then
              export EDITOR='nvim'
            else
              # export EDITOR='nvim'
              export EDITOR='code -w'
            fi

            # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
            # [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

            source ~/agents.sh

            # PATH="$PATH:/opt/bin:$HOME/.local/bin/"

            source $HOME/.dotbins/shell/zsh.sh
          '';
        in
        lib.mkMerge [
          zshConfigEarlyInit
          zshConfig
        ];
    };
    git = {
      enable = true;
      settings = {
        user = {
          name = "Lucas Fernando Cardoso Nunes";
          email = "lucasfc.nunes@gmail.com";
        };
        gpg.format = "ssh";
        user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlBdpRehqTLYT2XKNJndv0pMWCBuqdLUPCDc1xd2XLp (gpg-ssh-lucasfcnunes)";
        commit.gpgSign = true;
        init.defaultBranch = "master";
        safe.directory = "*";
        url."git@github.com:" = {
          insteadOf = "https://github.com/";
        };
        url."git@gist.github.com:" = {
          insteadOf = "https://gist.github.com/";
        };
        github = {
          user = "lucasfcnunes";
        };
        diff."sopsdiffer" = {
          textconv = "sops -d --config /dev/null";
        };
        # core = {
        #   editor = "nvim";
        # };
      };
    };
    gh = {
      enable = true;
      # settings.editor = "nvim";
    };
  };
}
