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
  npmMirror = builtins.getEnv "DOTFILES_NPM_MIRROR";
  pi-llama-swap = pkgs.fetchzip {
    urls =
      lib.optional (npmMirror != "") "${npmMirror}/@danielmeneses/pi-llama-swap/-/pi-llama-swap-0.1.2.tgz"
      ++ [ "https://registry.npmjs.org/@danielmeneses/pi-llama-swap/-/pi-llama-swap-0.1.2.tgz" ];
    sha256 = "0wbk556zihw1jngayg89farar1nl7aaai1hiaslv6mzzqfvx1yff";
  };
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
  # `.omp/agent/extensions` is no longer a `home.file` entry: herdr
  # self-installs/updates its own omp integration script inside this
  # directory at runtime, and a store-backed symlink makes that write
  # fail with EACCES (errno 13). Instead we ensure a real, writable
  # directory exists and drop in the extensions this repo owns (the
  # fetched pi-llama-swap package plus the mode-toggle and opencode-fix
  # scripts) as out-of-store symlinks; herdr remains free to create/rewrite
  # its own files alongside them.
  home.activation.linkOmpExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.omp/agent/extensions"
    run ln -sfn "${pi-llama-swap}" "$HOME/.omp/agent/extensions/pi-llama-swap"
    run ln -sfn "${files}/omp/extensions/mode-toggle.ts" "$HOME/.omp/agent/extensions/mode-toggle.ts"
    run ln -sfn "${files}/omp/extensions/opencode-fix.ts" "$HOME/.omp/agent/extensions/opencode-fix.ts"
  '';
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
