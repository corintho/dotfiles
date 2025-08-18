{ config, libFiles, pkgs, ... }:
let inherit (config.lib.stylix) colors;
in {
  config = {
    xdg.configFile = {
      "qtile/colors.py".text = ''

        # If using transparency, make sure you add (background="#00000000") to 'Screen' line(s).
        # Then, you can use RGBA color codes to add transparency to the colors below.
        # For ex: colors = [["#282c34ee", "#282c34dd"], ...

        Lcars = [
          ["#${colors.base01}", "#${colors.base01}"], # bg
          ["#${colors.base05}", "#${colors.base05}"], # fg
          ["#${colors.base02}", "#${colors.base02}"],
          ["#${colors.base07}", "#${colors.base07}"],
          ["#${colors.base0B}", "#${colors.base0B}"],
          ["#${colors.base09}", "#${colors.base09}"],
          ["#${colors.base0C}", "#${colors.base0C}"],
          ["#${colors.base0E}", "#${colors.base0E}"],
          ["#${colors.base0F}", "#${colors.base0F}"],
          ["#${colors.base09}", "#${colors.base09}"] 
        ]
      '';
    };
  };
}

