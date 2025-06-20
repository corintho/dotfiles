{ self, inputs, nixpkgs, nixpkgs-unstable, home-manager, secrets, paths, ... }:

let
  username = "corintho";
  rootPath = paths.rootPath;
  nixPath = "${rootPath}/nix";
  # Passes these parameters to other nix modules
  specialArgs = {
    inherit self inputs username nixPath rootPath secrets paths;
    files = "${rootPath}/files";
    libFiles = "${rootPath}/lib";
  };
in {
  ncc-1701-d = nixpkgs.lib.nixosSystem {
    inherit specialArgs;

    modules = [
      {
        nixpkgs.overlays = [
          (final: _prev: {
            unstable =
              import nixpkgs-unstable { inherit (final) system config; };
          })
          (_final: prev: {
            zjstatus = inputs.zjstatus.packages.${prev.system}.default;
          })
        ];
      }
      inputs.stylix.nixosModules.stylix
      inputs.agenix.nixosModules.default
      ../modules/secrets.nix
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
