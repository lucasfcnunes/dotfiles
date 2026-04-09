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
      ".config-systemd-user-files" = {
        target = "./.config/systemd/user";
        source = ./home/lucasfcnunes/.config/systemd/user;
        recursive = true;
      };
      "agents.sh" = {
        executable = true;
        source = ./home/lucasfcnunes/agents.sh;
      };
    };
  };
  # systemd.user.services = {
  #   gpg-agent.socket = {
  #   };
  #   gpg-agent-ssh.socket = {
  #   };
  # };
  programs = {
    home-manager.enable = true;
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
            ZSH_THEME="robbyrussell"

            # source $ZSH/oh-my-zsh.sh

            # Preferred editor for local and remote sessions
            if [[ -n $SSH_CONNECTION ]]; then
              export EDITOR='vim'
            else
              # export EDITOR='nvim'
              export EDITOR='code -w'
            fi

            # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
            # [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

            source ~/agents.sh

            # PATH="$PATH:/opt/bin:$HOME/.local/bin/"

            # # >>> mamba initialize >>>
            # # !! Contents within this block are managed by 'mamba init' !!
            # export MAMBA_EXE='/opt/bin/micromamba';
            # export MAMBA_ROOT_PREFIX='/home/lucasfcnunes/micromamba';
            # __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
            # if [ $? -eq 0 ]; then
            #     eval "$__mamba_setup"
            # else
            #     alias micromamba="$MAMBA_EXE"  # Fallback on help from mamba activate
            # fi
            # unset __mamba_setup
            # # <<< mamba initialize <<<

            # source $HOME/.dotbins/shell/zsh.sh
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
        user.signingKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7I5xIu1oxunktPOmR/HC+EqBJic2z0sbAn+mgluZdLKyDfHkdH/wSiH45jPplkJ473io3OAqJMo+0mgk7gRNSCzc93zj6fbM6JbQa3bC8FJ2uYFYGDkCtgqxgRpTCNcj8bL5inbcfrR3FcZK43ABtCatjqW8y2C39qvpdj0puxa/1Orm2lIxDubYd5oskqKcxUIIPatfFBACr6UXok2zmNDnZtU30f7C6At27nlcii1tNyuGFNVqocLj/qEKTMPp30LHgOewOmOE2u9cb/T39FvGBBJD1z84Xb/47XFREQyi/eBjzI6v5PyJMJ+1IiwI/fgjnxQAnHZqL1htTAcsXhrol5i/Cp08MEo2PkmtWyD3vzwYEMJSxLdghsEQ8ClH2u6QMI2uZIUQpsvNW6uCaH+ooRmcyP3UyspWEVeqSce2I3Iy8mBdCHO0od0Yeqc8P/0B6IfrSUyHXdYetCeRDP5VcpSKsn9/YnjhRW8QSARCV4TvkMwFJpjcZ3eUN3Tb2ix9wEDg9wHXn8nvh4AnfIWAbBffbIWtnT5+JId+h6NhcJlXwQjGRbVctbA6XcAx9AiIml1dr+VHv6hQDwdpEFXy1J58jEnwKJIOJLPp/n6G/7bgyr7H8JhBGIW35ZxzuMvml6amaTWUG2icsFLL/MO+ZuXVJ8JDeUmi0DS8fRw== (gpg-ssh-lucasfcnunes)";
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
        core = {
          editor = "nvim";
        };
      };
    };
    gh = {
      enable = true;
      settings.editor = "nvim";
    };
  };
}
