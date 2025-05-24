{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Custom pkgs for some modules
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, ... }: {
    nixosConfigurations = {
      ncc-1701-d = let
        username = "corintho";
        system = "x86_64-linux";
        rootPath = ../.;
        # Passes these parameters to other nix modules
        specialArgs = {
          inherit username;
          dotFiles = rootPath + /dotfiles;
          libFiles = rootPath + /lib;
          pkgs-unstable = import nixpkgs-unstable {
            # Recursively inherits system from the outer scope
            inherit system;
            # TODO: synchronize this to a host set variable. Is it possible?
            # Allow unfree packages
            config.allowUnfree = true;
          };
        };
      in nixpkgs.lib.nixosSystem {
        inherit specialArgs;

        modules = [
          ./hosts/ncc-1701-d
          ./users/${username}/nixos.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} =
              import ./users/${username}/home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
            # Sets home manager to use the same special args as flakes
            home-manager.extraSpecialArgs = inputs // specialArgs;
          }
        ];
      };
    };
  };
}
