{
  description = "NixOS configuration";

  inputs = {
    # Base packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05?shallow=1";
    home-manager = {
      # url = "github:nix-community/home-manager/release-25.05?shallow=1";
      url = "github:nix-community/home-manager?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Global styling through stylix
    stylix = {
      url = "github:nix-community/stylix/release-25.05?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Custom pkgs for some modules
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable?shallow=1";
    devenv.url = "github:cachix/devenv/latest";
    # Darwin specific packages
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin-linking = {
      url = "github:nix-darwin/nix-darwin/pull/1396/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Enable homebrew management through nix
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew?shallow=1";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle?shallow=1";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask?shallow=1";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core?shallow=1";
      flake = false;
    };
    homebrew-xcodesorg = {
      url = "github:xcodesorg/homebrew-made?shallow=1";
      flake = false;
    };
    # Enable agenix for secrets encryption
    agenix = {
      url = "github:ryantm/agenix?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url =
        "git+ssh://git@github.com/corintho/nix-secrets.git?shallow=1&ref=main";
      flake = false;
    };
    # Custom packages for software from other sources
    zen-browser = {
      url = "github:youwen5/zen-browser-flake?shallow=1";

      # optional, but recommended if you closely follow NixOS unstable so it shares
      # system libraries, and improves startup time
      # NOTE: if you experience a build failure with Zen, the first thing to check is to remove this line!
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zjstatus = { url = "github:dj95/zjstatus?shallow=1"; };
    # Workaround for absolute path requirements
    paths.url = ./paths;
  };

  outputs = inputs@{ self, paths, nixpkgs, nixpkgs-unstable, home-manager
    , nix-darwin, homebrew-bundle, homebrew-cask, homebrew-core
    , homebrew-xcodesorg, nix-homebrew, secrets, ... }: {
      nixosConfigurations = (import ./hosts {
        inherit self inputs nixpkgs nixpkgs-unstable home-manager paths secrets;
      });
      darwinConfigurations = (import ./darwin {
        inherit self inputs nix-darwin nixpkgs nixpkgs-unstable nix-homebrew
          home-manager homebrew-bundle homebrew-cask homebrew-core
          homebrew-xcodesorg paths;
      });
    };
}
