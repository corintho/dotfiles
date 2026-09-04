{ inputs, pkgs, system }:
let
  herdrToolchainFile = builtins.fromTOML (builtins.readFile "${inputs.herdr}/rust-toolchain.toml");
  rustOverlayPkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ inputs.rust-overlay.overlays.default ];
  };
  herdrRustToolchain = rustOverlayPkgs.rust-bin.fromRustupToolchain (
    herdrToolchainFile.toolchain // { profile = "minimal"; }
  );
in
inputs.herdr.packages.${system}.default.override {
  rustPlatform = rustOverlayPkgs.makeRustPlatform {
    cargo = herdrRustToolchain;
    rustc = herdrRustToolchain;
  };
}
