{ config, pkgs, files, libFiles, ... }:

{
  config = {
    home.packages = with pkgs; [
      playerctl # media player cli
      gobject-introspection # for python packages
      (python3.withPackages
        (ps: with ps; [ pygobject3 ])) # python with pygobject3
      lm_sensors # sensors information library
      jq
      openpomodoro-cli
    ];

    home.file = {
      ".config/waybar/config.jsonc" = {
        source = "${files}/waybar/config.jsonc";
      };
      ".config/waybar/style.css" = { source = "${files}/waybar/style.css"; };
      ".config/waybar/theme.css" = {
        text = ''
          /* Global colors */
          @define-color bar-bg rgba(0, 0, 0, 0);

          @define-color main-bg ${config.lib.stylix.colors.withHashtag.base01};
          @define-color main-fg ${config.lib.stylix.colors.withHashtag.base05};

          /* Workspace buttons */
          @define-color wbar-bg ${config.lib.stylix.colors.withHashtag.base02};
          @define-color bar-active ${config.lib.stylix.colors.withHashtag.base0B};
          @define-color bar-active-other ${config.lib.stylix.colors.withHashtag.base0D};
          @define-color bar-other ${config.lib.stylix.colors.withHashtag.base09};

          /* Current workspace button */
          @define-color wb-current-bg @bar-active;
          @define-color wb-current-fg @wbar-bg;

          /* Active button (in another monitor) */
          @define-color wb-act-bg @main-bg;
          @define-color wb-act-fg @bar-active;

          /* Visible button */
          @define-color wb-vis-bg @main-bg;
          @define-color wb-vis-fg @bar-active-other;

          /* Hovered button */
          @define-color wb-hvr-bg @bar-other;
          @define-color wb-hvr-fg @wbar-bg;
          /* /Workspace buttons */
        '';
      };
      ".local/lib/waybar/" = {
        source = "${libFiles}/waybar";
        recursive = true;
      };
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };
  };
}
