#!/bin/sh

# export SSH_AUTH_SOCK=`echo "${XDG_RUNTIME_DIR:-${HOME}}/ssh/agent.sock" | tr -s /`
# export GPG_TTY=$(tty)
# export GPG_AGENT_SOCK=`echo "${XDG_RUNTIME_DIR:-${HOME}}/gnupg/S.gpg-agent" | tr -s /`
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
