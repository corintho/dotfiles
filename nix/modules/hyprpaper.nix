# TODO: Make the folder reference dynamic through a variable
let wallpaper = "~/.local/share/wallpapers/973571.jpg";
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
