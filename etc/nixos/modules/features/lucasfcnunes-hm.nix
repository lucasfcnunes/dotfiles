{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.lucasfcnunes-hm =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        # TODO: auto import if, and only if, not imported already
        # self.nixosModules.home-manager
      ];
      environment.systemPackages = with pkgs; [
        # fish
        # starship # prompt
        zsh
        zsh-powerlevel10k
        direnv
        git
        gnupg
        curl
        wget
        # vimrm -rf
        neovim
        micromamba
        busybox
        # psmisc
        # parted
        unstable.devenv
      ];
      programs = {
        # starship = {
        #   enable = true;
        # };
        # fish = {
        #   enable = true;
        #   interactiveShellInit = ''
        #     set fish_greeting ""
        #     starship init fish | source
        #     fzf --fish | source
        #   '';
        # };
        zsh = {
          enable = true;
        };
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
      users.users.lucasfcnunes = {
        isNormalUser = true;
        shell = pkgs.zsh;
      };
      home-manager.users.lucasfcnunes = self.homeModules.lucasfcnunes;
    };
  flake.homeConfigurations.lucasfcnunes = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
    modules = [
      self.homeModules.lucasfcnunes
      {
        home.username = "lucasfcnunes";
        home.homeDirectory = "/home/lucasfcnunes";
      }
    ];
  };
  flake.homeModules.lucasfcnunes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      my-name = "Lucas Fernando Cardoso Nunes";
      my-email = "lucasfc.nunes@gmail.com";
      my-gpg = "51BBB719DB9A3F8A928A4D5C9D76B9D8E1E20E99";
      my-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlBdpRehqTLYT2XKNJndv0pMWCBuqdLUPCDc1xd2XLp (gpg-ssh-lucasfcnunes)";
    in
    {
      imports = [
        self.homeModules.npiperelay-wsl
      ];
      home = {
        stateVersion = "25.05";
        # username = "lucasfcnunes";
        # homeDirectory = "/home/lucasfcnunes";
        sessionPath = [
          "$HOME/.dotbins/linux/amd64/bin"
        ];
        packages = with pkgs; [
          fastfetch
          # systemctl-tui
          # (pkgs.writeShellApplication {
          #   name = "ns";
          #   runtimeInputs = with pkgs; [
          #     fzf
          #     nix-search-tv
          #   ];
          #   text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
          # })
        ];
      };
      programs = {
        home-manager.enable = true;
        gpg = {
          # INFO: https://home-manager-options.extranix.com/?query=programs.gpg&release=release-25.11
          enable = true;
          settings = {
            # default-key = my-gpg;
            # personal-digest-preferences = "SHA512";
            # cert-digest-algo = "SHA512";
            # default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed";
            # no-emit-version = true;
            # always use options on CLI
            keyid-format = "LONG";
            with-fingerprint = true;
            with-keygrip = true;
          };
          publicKeys = [
            {
              source = pkgs.fetchurl {
                url = "https://keybase.io/lucasfcnunes/pgp_keys.asc?fingerprint=${lib.toLower my-gpg}";
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
            btw = "echo i use nixos, btw";
            ll = "ls -l";
            update = "sudo nixos-rebuild switch --flake ~/dotfiles/etc/nixos/";
            docker2 = "nix run nixpkgs/nixpkgs-unstable#docker-client -- ";
            # devenv2 = "nix run github:cachix/devenv/v2.2 -- ";
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

                # PATH="$PATH:/opt/bin:$HOME/.local/bin/"

                [[ ! -f ~/.dotbins/shell/zsh.sh ]] || source ~/.dotbins/shell/zsh.sh

                # eval "$(devenv hook zsh)" # ! using direnv for now
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
            # INFO: https://git-scm.com/docs/git-config
            user = {
              name = my-name;
              email = my-email;
            };
            gpg.format = "ssh";
            user.signingKey = my-ssh;
            # gpg.format = "gpg";
            # user.signingKey = my-gpg;
            commit.gpgSign = true;
            tag.gpgSign = true;
            tag.forceSignAnnotated = true;
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
            log = {
              abbrevCommit = true;
              showSignature = true;
            };
          };
        };
        jujutsu = {
          enable = true;
          settings = {
            user = {
              name = my-name;
              email = my-email;
            };
            signing = {
              behavior = "own";
              # backend = "gpg";
              # key = my-gpg;
              backend = "ssh";
              key = my-ssh;
            };
          };
        };
        jjui.enable = true;
        gh = {
          enable = true;
          # settings.editor = "nvim";
        };
        # atuin = {
        #   enable = true;
        #   daemon.enable = true;
        #   enableBashIntegration = true;
        #   enableZshIntegration = true;
        #   enableFishIntegration = true;
        #   enableNushellIntegration = true;
        # };
      };
    };
}
