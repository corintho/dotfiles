{
  description = "NixOS configuration";

  inputs = {
    # Base packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Custom pkgs for some modules
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Darwin specific packages
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Enable homebrew management through nix
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-xcodesorg = {
      url = "github:xcodesorg/homebrew-made";
      flake = false;
    };
    # Custom packages for software from other sources
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";

      # optional, but recommended if you closely follow NixOS unstable so it shares
      # system libraries, and improves startup time
      # NOTE: if you experience a build failure with Zen, the first thing to check is to remove this line!
      inputs.nixpkgs.follows = "nixpkgs";
    };
    paths.url = ./paths;
  };

  outputs = inputs@{ self, paths, nixpkgs, nixpkgs-unstable, home-manager
    , nix-darwin, homebrew-bundle, homebrew-cask, homebrew-core
    , homebrew-xcodesorg, nix-homebrew, ... }: {
      # imports = [ ./paths2.nix ];
      nixosConfigurations = (import ./hosts {
        inherit inputs nixpkgs nixpkgs-unstable home-manager paths;
      });
      darwinConfigurations = (import ./darwin {
        inherit self nix-darwin nixpkgs nix-homebrew home-manager
          homebrew-bundle homebrew-cask homebrew-core homebrew-xcodesorg paths;
      });
    };
}
