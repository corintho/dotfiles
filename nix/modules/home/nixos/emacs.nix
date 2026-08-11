{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Ship the Spacemacs artwork as a standalone hicolor theme icon under a
  # fresh name (emacs-spacemacs). The packaged emacs provides emacs.svg/emacs.png
  # in the same theme, and Qt's icon loader lets those stock PNGs win over any
  # user-supplied "emacs" file; emacs-spacemacs has no stock PNGs anywhere, so
  # the scalable SVG is the only candidate and always wins. home.packages places
  # the icon in the home-manager profile's share/icons, which IS in Qt's icon
  # theme search path (unlike ~/.local/share/icons).
  spacemacsEmacsIcon = pkgs.runCommand "spacemacs-emacs-icon" { } ''
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp ${inputs.spacemacs}/assets/spacemacs.svg $out/share/icons/hicolor/scalable/apps/emacs-spacemacs.svg
  '';
in
{
  home.packages = [ spacemacsEmacsIcon ];

  # Point the Emacs desktop entries at the Spacemacs icon name so launchers (e.g.
  # vicinae, which resolves QIcon::fromTheme from the desktop entry's Icon=)
  # show the Spacemacs artwork instead of the stock GNU icon. These entries are
  # installed with hiPrio, so they override the packaged ones.
  #
  # home-manager's services.emacs.client also generates an emacsclient.desktop
  # (also hiPrio); disable it to avoid a buildEnv collision since we provide
  # our own with the Spacemacs icon.
  services.emacs.client.enable = lib.mkForce false;
  xdg.desktopEntries = {
    emacs = {
      type = "Application";
      name = "Emacs";
      genericName = "Text Editor";
      comment = "Edit text";
      exec = "emacs %F";
      icon = "emacs-spacemacs";
      terminal = false;
      startupNotify = true;
      categories = [
        "Development"
        "TextEditor"
      ];
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];
      settings.StartupWMClass = "Emacs";
    };
    emacsclient = {
      type = "Application";
      name = "Emacs (Client)";
      genericName = "Text Editor";
      comment = "Edit text";
      exec = "emacsclient --alternate-editor= --create-frame %F";
      icon = "emacs-spacemacs";
      terminal = false;
      startupNotify = true;
      categories = [
        "Development"
        "TextEditor"
      ];
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
        "x-scheme-handler/org-protocol"
      ];
      settings.StartupWMClass = "Emacs";
    };
  };

  # GUI-launched (GDM) Emacs runs in the systemd user session, which reads
  # ~/.config/environment.d/*.conf — not shell profiles. Expose the Spacemacs
  # vars there so launchers and the systemd-managed daemon both see them.
  systemd.user.sessionVariables = {
    EMACSDIR = "${config.xdg.configHome}/emacs";
    SPACEMACSDIR = "${config.xdg.configHome}/spacemacs";
  };

  # NixOS daemon: socket activation starts Emacs on first emacsclient request.
  services.emacs.socketActivation.enable = true;
}
