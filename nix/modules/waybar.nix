{ pkgs, dotFiles, libFiles, ... }:

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
      ".config/waybar/" = {
        source = dotFiles + /waybar;
        recursive = true;
      };
      ".local/lib/waybar/" = {
        source = libFiles + /waybar;
        recursive = true;
      };
    };

    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };
  };
}
