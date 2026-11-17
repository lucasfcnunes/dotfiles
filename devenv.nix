{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/basics/
  env.PROJECT_ROOT = config.git.root;
  env.GREET = "devenv";
  # env.NIX_CONFIG="extra-substituters = https://nix-community.cachix.org https://numtide.cachix.org";
  # env.KUBECONFIG="${KUBECONFIG}${KUBECONFIG:+:}$HOME/.kube/nixos-01/kubeconfig";
  env.KUBECTL_EXTERNAL_DIFF = "dyff between --omit-header --set-exit-code";
  # env.HELM_BIN="$(which helm4)";
  # env.HELM_BIN="$(which helm3)";
  env.HELM_DIFF_OUTPUT = "dyff";
  env.HELM_DIFF_THREE_WAY_MERGE = "true";
  env.CONFIG_FILE = "${config.env.PROJECT_ROOT}/dotbins.yaml";
  # env.TOOLS_DIR = "${HOME}/.dotbins";
  # env.GITHUB_TOKEN=$(gh auth token);
  env.K8S_SERVICE_HOST = "100.69.10.63";
  env.K8S_SERVICE_PORT = "6443";

  # https://devenv.sh/packages/
  packages = [ pkgs.git ];

  # https://devenv.sh/languages/
  languages.python.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    hello         # Run scripts directly
    git --version # Use packages
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
