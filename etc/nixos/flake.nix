{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
  inputs = {
    # TODO: use a builtin patching pattern https://github.com/NixOS/nix/issues/3920
    nixpkgs-upstream.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs.url = "github:lucasfcnunes/nixpkgs/nixos-26.05";
    nixpkgs-patch-01 = {
      # nixos/dnscrypt-proxy
      url = "https://github.com/NixOS/nixpkgs/pull/548856.patch";
      flake = false;
    };
    nixpkgs-patch-02 = {
      # pkgs.windows.npiperelay
      url = "https://github.com/NixOS/nixpkgs/pull/528466.patch";
      flake = false;
    };
    nixpkgs-patch-03 = {
      # nixos/kubernetes (fix: aggregation layer)
      url = "https://github.com/NixOS/nixpkgs/pull/531462.patch";
      flake = false;
    };
    nixpkgs-patch-04 = {
      # nixos/hyperv: Fix hotplug and IO scheduler warnings on boot
      url = "https://github.com/NixOS/nixpkgs/pull/467257.patch";
      flake = false;
    };
    nixpkgs-patch-05 = {
      # pkgs.linuxPackages.dxgkrnl (nixos/hyperv-guest: add GPU-PV (dxgkrnl) support)
      url = "https://github.com/NixOS/nixpkgs/compare/master...lucasfcnunes:nixpkgs:lostmsu-dxgkrnl.patch";
      # url = "https://github.com/NixOS/nixpkgs/pull/502687.patch";
      flake = false;
    };
    # nixpkgs-patch-06 = {
    #   # pkgs.rocmPackages.amdsmi: fix error: wsl2 support
    #   url = "https://github.com/lucasfcnunes/nixpkgs/pull/2.patch";
    #   flake = false;
    # };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.flake-parts.follows = "flake-parts";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    oisd = {
      url = "github:sjhgvr/oisd";
      flake = false;
    };
    nix-on-droid = {
      # TODO: set to 26.05
      url = "github:nix-community/nix-on-droid/prerelease-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };
}
