{ config, ... }:
let inherit (config.lib.stylix) colors;
in {
  services = {
    jankyborders = {
      enable = true;
      hidpi = false;
      style = "round";
      width = 4.0;
      active_color = "0xff${colors.base0D}";
      inactive_color = "0xff${colors.base03}";
    };
  };

}
