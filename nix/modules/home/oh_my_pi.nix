{
  config,
  files,
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
  };

  home.file.".omp/agent/config.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/omp/config.yml";
  home.file.".omp/agent/keybindings.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/omp/keybindings.yml";
  home.file.".omp/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/omp/extensions";
  home.file.".omp/plugins".source = config.lib.file.mkOutOfStoreSymlink "${files}/omp/plugins";
  home.file.".omp/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/agents/AGENTS.md";
}
