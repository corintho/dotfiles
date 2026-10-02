{
  self,
  inputs,
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  secrets,
  paths,
  local_flutter_path,
  flutter-local,
  ...
}:

let
  system = "x86_64-linux";
  username = "corintho";
  rootPath = paths.rootPath;
  nixPath = "${rootPath}/nix";
  pkgs = import nixpkgs { inherit system; };
  lcarsConfig = import ../features.nix { inherit pkgs; };
  # Passes these parameters to other nix modules
  specialArgs = {
    inherit
      self
      inputs
      username
      nixPath
      rootPath
      secrets
      paths
      local_flutter_path
      flutter-local
      ;
    files = "${rootPath}/files";
    libFiles = "${rootPath}/lib";
    lcars = lcarsConfig.lcars;
  };
in
{
  ncc-1701-d = nixpkgs.lib.nixosSystem {
    inherit specialArgs;

    modules = [
      {
        nixpkgs.overlays = [
          inputs.emacs-overlay.overlays.default
          (final: _prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              inherit (final) config;
              overlays = [
                # Pin llama.cpp to upstream nightly b10964 for Blackwell GDN support
                # (qwen35 hybrid linear attention: Qwen3.8-27B-Ridge, MiMo-V2.6-Distill).
                # Override source only; keep nixpkgs' CUDA toolchain/flags to avoid the
                # known sm_120 codegen bug from newer CUDA.
                (uFinal: uPrev: {
                  llama-cpp = uPrev.llama-cpp.overrideAttrs (old: {
                    version = "10964";
                    src = uPrev.fetchFromGitHub {
                      owner = "ggml-org";
                      repo = "llama.cpp";
                      rev = "b10964";
                      hash = "sha256-/BOx808d4TV/oraX92sarx5VExvxF3sCofIy9h3Akgg==";
                    };
                    npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
                  });
                })
              ];
            };
          })
          # TODO: Remove once primp upstream fixes pytestFlagsArray deprecation
          (final: prev: {
            python3Packages = prev.python3Packages.override {
              overrides = pyfinal: pyprev: {
                primp = pyprev.primp.overrideAttrs (old: {
                  pytestFlagsArray = null;
                  pytestFlags = [
                    "-o"
                    "asyncio_mode=auto"
                  ];
                });
              };
            };
          })
          # TODO: Remove once openldap test017-syncreplication-refresh passes in sandbox
          (final: prev: {
            openldap = prev.openldap.overrideAttrs (old: {
              doCheck = false;
            });
          })
          # FreeCAD as AppImage (avoids netgen 6.2 API incompatibility at build time)
          (final: prev: {
            freecad = final.callPackage ../modules/freecad-appimage.nix { };
          })
        ];

        # Global packageOverrides for broader coverage
        nixpkgs.config.packageOverrides = pkgs: {
          openldap = pkgs.openldap.overrideAttrs (old: {
            doCheck = false;
          });
        };
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
        home-manager.users.${username} = import "${nixPath}/users/${username}/home.nix";

        # Optionally, use home-manager.extraSpecialArgs to pass
        # arguments to home.nix
        # Sets home manager to use the same special args as flakes
        home-manager.extraSpecialArgs = inputs // specialArgs;
      }
    ];
  };
}
