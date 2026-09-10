{
  config,
  files,
  inputs,
  lib,
  pkgs,
  rootPath,
  ...
}:

let
  filesDir = builtins.path {
    path = files;
    name = "dotfiles-files";
  };
  pi-llama-swap = pkgs.fetchzip {
    url = "https://registry.npmjs.org/@danielmeneses/pi-llama-swap/-/pi-llama-swap-0.1.2.tgz";
    sha256 = "0wbk556zihw1jngayg89farar1nl7aaai1hiaslv6mzzqfvx1yff";
  };
  mergedExtensions = pkgs.runCommand "omp-extensions" { } ''
    mkdir -p $out
    cp -r ${filesDir}/omp/extensions/* $out/
    mkdir -p $out/pi-llama-swap
    cp -r ${pi-llama-swap}/* $out/pi-llama-swap/
  '';
  models = config.lcars.models or { };
  piLlamaSwapJson = (pkgs.formats.json { }).generate "pi-llama-swap.json" {
    contextOverrides = builtins.mapAttrs (_: model: model.contextSize) models;
  };
in
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
  home.file.".omp/agent/extensions".source = mergedExtensions;
  # Whole-directory out-of-store symlink (same precedent as `.omp/plugins`
  # below) rather than the `mergedExtensions` build-derivation pattern used
  # for `.omp/agent/extensions` above: this directory has no third-party
  # package to merge in, so a live-editable directory symlink is simpler
  # and correct.
  home.file.".omp/agent/agents".source = config.lib.file.mkOutOfStoreSymlink "${files}/omp/agents";
  home.file.".omp/plugins".source = config.lib.file.mkOutOfStoreSymlink "${files}/omp/plugins";
  home.file.".omp/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/agents/AGENTS.md";

  # Coding-agent skills/commands/lockfile, shared across harnesses via
  # `files/agents`. Per-entry symlinks (not a whole-directory symlink of
  # `files/agents`) because `files/agents/AGENTS.md` above must not also
  # appear inside `~/.agents`.
  home.file.".agents/skills".source = config.lib.file.mkOutOfStoreSymlink "${files}/agents/skills";
  home.file.".agents/commands".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/agents/commands";
  home.file.".agents/.skill-lock.json".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/agents/.skill-lock.json";

  # Install the post-commit hook that rsyncs files/agents/{skills,commands,
  # .skill-lock.json} out to AGENTS_SYNC_TARGET (see
  # files/git-hooks/agents-sync-post-commit); no-op unless that env var is
  # configured.
  home.activation.installAgentsSyncHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${rootPath}/.git/hooks"
    run ln -sf "${files}/git-hooks/agents-sync-post-commit" "${rootPath}/.git/hooks/post-commit"
  '';
  home.file.".pi/agent/pi-llama-swap.json".source = piLlamaSwapJson;
  home.sessionVariables = {
    LLAMA_SWAP_PORT = "1234";
  };
}
