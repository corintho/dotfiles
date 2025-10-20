{ config, files, pkgs, ... }:

let inherit (config.lib.stylix) colors;
in {
  # extra packages for niri
  home.packages = with pkgs; [
    unstable.xdg-desktop-portal-gtk
    unstable.xdg-desktop-portal-gnome
    unstable.xwayland-satellite
  ];

  xdg.configFile = {
    "niri/layout_colors.kdl".text = ''
      layout {
        focus-ring {
          active-color "#${colors.base07}"
          active-gradient from="#${colors.base07}" to="#${colors.base0D}" angle=90
          inactive-color "#${colors.base04}"
          inactive-gradient from="#${colors.base03}" to="#${colors.base04}" angle=90
        }
      }
    '';
  };
  xdg.configFile = { "niri/config.kdl" = { source = ./niri/config.kdl; }; };

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
