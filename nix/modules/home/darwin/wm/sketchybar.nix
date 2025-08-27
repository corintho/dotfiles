{ pkgs, ... }: {
  config = {
    programs.sketchybar = {
      enable = true;
      package = pkgs.unstable.sketchybar;
      config = {
        source = ./sketchybar;
        recursive = true;
      };
    };
  };
}

