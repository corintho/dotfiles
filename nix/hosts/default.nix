{ self, inputs, nixpkgs, nixpkgs-unstable, home-manager, secrets, paths
, local_flutter_path, flutter-local, ... }:

let
  system = "x86_64-linux";
  username = "corintho";
  rootPath = paths.rootPath;
  nixPath = "${rootPath}/nix";
  pkgs = import nixpkgs { inherit system; };
  lcarsConfig = import ../features.nix { inherit pkgs; };
  # Passes these parameters to other nix modules
  specialArgs = {
    inherit self inputs username nixPath rootPath secrets paths
      local_flutter_path flutter-local;
    files = "${rootPath}/files";
    libFiles = "${rootPath}/lib";
    lcars = lcarsConfig.lcars;
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
          # Override for open-webui dependency
          (final: prev: {
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (python-final: python-prev: {
                rapidocr-onnxruntime =
                  python-prev.rapidocr-onnxruntime.overridePythonAttrs
                  (oldAttrs: rec {
                    version = "2.1.0";
                    src = prev.fetchFromGitHub {
                      owner = "RapidAI";
                      repo = "RapidOCR";
                      tag = "v${version}";
                      hash =
                        "sha256-4R2rOCfnhElII0+a5hnvbn+kKQLEtH1jBvfFdxpLEBk=";
                    };
                    doCheck = false;
                  });
              })
            ];
          })
        ];
      }
      inputs.stylix.nixosModules.stylix
      inputs.agenix.nixosModules.default
      ../options/default.nix
      ../features.nix
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
