{
  config,
  lib,
  pkgs,
  ...
}:

{
  # GUI-launched (GDM) Emacs runs in the systemd user session, which reads
  # ~/.config/environment.d/*.conf — not shell profiles. Expose the Doom vars
  # there so launchers and the systemd-managed daemon both see them.
  systemd.user.sessionVariables = {
    EMACSDIR = "${config.xdg.configHome}/emacs";
    DOOMDIR = "${config.xdg.configHome}/doom";
    DOOMLOCALDIR = "${config.xdg.dataHome}/doom";
    DOOMPROFILELOADFILE = "${config.xdg.stateHome}/doom-profiles-load.el";
  };

  # NixOS daemon: socket activation starts Emacs on first emacsclient request.
  services.emacs.socketActivation.enable = true;
}
