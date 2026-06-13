{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
  inputs = {
    # TODO: use a builtin patching pattern https://github.com/NixOS/nix/issues/3920
    nixpkgs-upstream.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs.url = "github:lucasfcnunes/nixpkgs/nixos-26.05";
    nixpkgs-patch-01 = {
      # dnscrypt-proxy
      url = "https://github.com/NixOS/nixpkgs/pull/523222.patch";
      flake = false;
    };
    nixpkgs-patch-02 = {
      # windows.npiperelay
      url = "https://github.com/NixOS/nixpkgs/pull/528466.patch";
      flake = false;
    };
    nixpkgs-patch-03 = {
      # services.kubernetes (fix: aggregation layer)
      url = "https://github.com/NixOS/nixpkgs/pull/531462.patch";
      flake = false;
    };
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
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "https://big.oisd.nl/domainswild";
      flake = false;
    };
  };
}
