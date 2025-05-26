{ inputs, nixpkgs, nixpkgs-unstable, home-manager, ... }:

let
  username = "corintho";
  system = "x86_64-linux";
  rootPath = ../../.;
  nixPath = rootPath + /nix;
  # Passes these parameters to other nix modules
  specialArgs = {
    inherit inputs username nixPath rootPath;
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
in {
  ncc-1701-d = nixpkgs.lib.nixosSystem {
    inherit specialArgs;

    modules = [
      ./ncc-1701-d
      "${nixPath}/users/${username}/nixos.nix"

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} =
          import "${nixPath}/users/${username}/home.nix";

        # Optionally, use home-manager.extraSpecialArgs to pass
        # arguments to home.nix
        # Sets home manager to use the same special args as flakes
        home-manager.extraSpecialArgs = inputs // specialArgs;
      }
    ];
  };
}
