{ config, pkgs, ... }:
let inherit (config.lib.stylix) colors;
in {
  services = {
    jankyborders = {
      enable = true;
      package = pkgs.unstable.jankyborders;
      hidpi = false;
      style = "round";
      width = 6.0;
      active_color = "0xff${colors.base0D}";
      inactive_color = "0xff${colors.base03}";
    };
  };

}
