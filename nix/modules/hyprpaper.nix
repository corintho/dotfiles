{ config, ... }:
let wallpaper = config.stylix.image;
in {
  config = {

    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ "${wallpaper}" ];
        wallpaper = [ ",${wallpaper}" ];
      };
    };
  };
}
