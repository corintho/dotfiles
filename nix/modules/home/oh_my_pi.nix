{
  config,
  files,
  inputs,
  lib,
  pkgs,
  rootPath,
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
}
