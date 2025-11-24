{ pkgs, ... }:
{
  services = {
    jankyborders = {
      enable = true;
      package = pkgs.unstable.jankyborders;
      hidpi = false;
      style = "round";
      width = 6.0;
    };
  };

}
