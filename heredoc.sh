# bug on sops --rm-age A if --add-age A was used more than 01 time.
cat <<'EOF' | docker run --rm -i --entrypoint='' ghcr.io/getsops/sops:v3.13.1 bash
  set -xeuo pipefail
  export GPG_TTY=$(tty)
  cd
  ls -la
  gpg --no-tty --expert --full-generate-key
  gpg --no-tty --list-secret-keys --keyid-format LONG
EOF
