{ config, files, pkgs, ... }:

{

  # extra packages for niri
  home.packages = with pkgs; [
    unstable.xdg-desktop-portal-gtk
    unstable.xdg-desktop-portal-gnome
    unstable.xwayland-satellite
  ];

  xdg.configFile = {
    "niri" = { source = config.lib.file.mkOutOfStoreSymlink "${files}/niri"; };
  };

  xdg.desktopEntries = {
    bazecor = {
      type = "Application";
      name = "Bazecor (X11)";
      exec = "bazecor --ozone-platform=x11 %U";
      icon = "bazecor";
      categories = [ "Utility" ];
    };
  };
}
