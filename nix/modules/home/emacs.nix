{
  config,
  lib,
  pkgs,
  files,
  ...
}:

let
  emacsPackage = if pkgs.stdenv.isLinux then pkgs.emacs-pgtk else pkgs.emacs;
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
    # Doom itself lives in a writable git clone pinned by `just emacs-setup` to
    # the flake-locked doom revision (see Justfile), so it is not store-managed
    "doom".source = config.lib.file.mkOutOfStoreSymlink "${files}/doom";
  };

  home.sessionVariables = {
    EMACSDIR = "${config.xdg.configHome}/emacs";
    DOOMDIR = "${config.xdg.configHome}/doom";
    # Mutable Doom state (straight.el, caches, package installs) lives
    # outside both the store and the tracked config
    DOOMLOCALDIR = "${config.xdg.dataHome}/doom";
    DOOMPROFILELOADFILE = "${config.xdg.stateHome}/doom-profiles-load.el";
  };

  home.sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];

  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.isLinux true;
}
