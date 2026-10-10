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
                # Global cudaSupport makes the opencv that mlt builds (opencv4 + ffmpeg_8) a CUDA
                # build that no binary cache serves (~110 min to compile). krita (from unstable)
                # takes mlt from kdePackages; nothing here needs CUDA opencv. Scoped to that mlt
                # so unstable.opencv stays the CUDA build served by cache.nixos-cuda.org.
                (uFinal: uPrev: {
                  kdePackages = uPrev.kdePackages.overrideScope (
                    _kfinal: kprev: {
                      mlt = kprev.mlt.override { opencv4 = uPrev.opencv4WithoutCuda; };
                    }
                  );
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
          # FreeCAD as AppImage (avoids netgen 6.2 API incompatibility at build time)
          (final: prev: {
            freecad = final.callPackage ../modules/freecad-appimage.nix { };
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
        home-manager.users.${username} = import "${nixPath}/users/${username}/home.nix";

        # Optionally, use home-manager.extraSpecialArgs to pass
        # arguments to home.nix
        # Sets home manager to use the same special args as flakes
        home-manager.extraSpecialArgs = inputs // specialArgs;
      }
    ];
  };
}
