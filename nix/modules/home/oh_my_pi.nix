{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # oh-my-pi ("omp") coding-agent harness. The Home Manager module that
  # defines `programs.omp` (and its `package` option) is imported in the user
  # home configs via `inputs.omp.homeManagerModules.default`.
  #
  # The binary itself comes from `yuxqiu/omp-nix`, which ships prebuilt
  # release binaries (no local Rust/Bun compile). This keeps the install
  # declarative without the multi-minute source build.
  programs.omp = {
    enable = true;
    package = inputs.omp-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings.startup.quiet = true;
  };
}
