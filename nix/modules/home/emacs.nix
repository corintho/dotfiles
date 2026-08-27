{
  config,
  lib,
  pkgs,
  files,
  ...
}:

let
  emacsPackage = if pkgs.stdenv.isLinux then pkgs.emacs-unstable-pgtk else pkgs.emacs-unstable;
in
{
  home.packages = with pkgs; [
    emacsPackage
    # Doom 3 uses nerd-icons; provides the Symbols Nerd Font Mono family
    nerd-fonts.symbols-only
    # Emacs' fallback font for exotic/absent glyphs
    symbola
    # Required Doom dependency per getting_started.org
    ripgrep
    # :lang markdown markdown-preview backend
    pandoc
    # :lang sh linting backend
    shellcheck
  ];

  xdg.configFile = {
    # User config, writable and version controlled in the repo
    # Spacemacs itself lives in a writable git clone pinned by `just emacs-setup`
    # to the flake-locked spacemacs revision (see Justfile), so it is not
    # store-managed
    "spacemacs".source = config.lib.file.mkOutOfStoreSymlink "${files}/spacemacs";
  };

  home.sessionVariables = {
    EMACSDIR = "${config.xdg.configHome}/emacs";
    # Spacemacs dotfile directory (must exist for the env var to take effect)
    SPACEMACSDIR = "${config.xdg.configHome}/spacemacs";
  };

  # Emacs daemon + emacsclient, shared across platforms. Socket activation is
  # configured per-platform (see nixos/emacs.nix). EDITOR stays as Helix (`hx`),
  # so defaultEditor is intentionally left off.
  services.emacs = {
    enable = true;
    package = emacsPackage;
    client.enable = true;
  };

  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.isLinux true;
}
