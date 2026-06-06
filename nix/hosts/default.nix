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
              import nixpkgs-unstable { inherit system; inherit (final) config; };
          })
          # TODO: Remove this override once Sphinx/docutils compatibility is fixed
          # in nixpkgs-unstable (currently broken in commit 7aaa00e7).
          # See: https://github.com/NixOS/nixpkgs/issues/...
          (final: prev: {
            python312 = prev.python312.overrideAttrs (old: {
              passthru = old.passthru // {
                doc =
                  null; # Disable doc derivation to work around Sphinx incompatibility
              };
            });
          })
          # TODO: Remove once primp upstream fixes pytestFlagsArray deprecation
          (final: prev: {
            python3Packages = prev.python3Packages.override {
              overrides = pyfinal: pyprev: {
                primp = pyprev.primp.overrideAttrs (old: {
                  pytestFlagsArray = null;
                  pytestFlags = [ "-o" "asyncio_mode=auto" ];
                });
              };
            };
          })
          # TODO: Remove once openldap test017-syncreplication-refresh passes in sandbox
          (final: prev: {
            openldap = prev.openldap.overrideAttrs (old: { doCheck = false; });
          })
          # Fix netgen pybind11 incompatibility (keep_alive not supported on properties in pybind11 3.x)
          (final: prev: {
            netgen = prev.netgen.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace libsrc/meshing/python_mesh.cpp \
                  --replace-fail ', py::keep_alive<0,1>()' ""
              '';
            });
          })
          # Enable NETGEN mesher and add CalculiX solver for FreeCAD FEM
          (final: prev: {
            freecad = prev.freecad.overrideAttrs (old: {
              buildInputs = old.buildInputs ++ [ final.netgen final."calculix-ccx" ];
              cmakeFlags = old.cmakeFlags ++ [
                (final.lib.cmakeBool "BUILD_FEM_NETGEN" true)
              ];
              qtWrapperArgs = old.qtWrapperArgs ++ [
                "--prefix PATH : ${final."calculix-ccx"}/bin"
                "--prefix PYTHONPATH : ${final.netgen}/${final.python3Packages.python.sitePackages}"
              ];
              postPatch = old.postPatch + ''
                substituteInPlace src/Mod/Fem/femmesh/netgentools.py \
                  --replace-fail '"-E",' ""
              '';
            });
          })
        ];

        # Global packageOverrides for broader coverage
        nixpkgs.config.packageOverrides = pkgs: {
          openldap = pkgs.openldap.overrideAttrs (old: { doCheck = false; });
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
