{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Same helper stylix's jankyborders target uses, so alpha stays consistent
  mkColor =
    base:
    config.lib.stylix.mkOpacityHexColor config.lib.stylix.colors.${base} config.stylix.opacity.desktop;
in
{
  services = {
    jankyborders = {
      enable = true;
      package = pkgs.unstable.jankyborders;
      hidpi = false;
      style = "round";
      width = 6.0;
      # Override stylix's default (base0D) with the purple accent
      active_color = lib.mkForce (mkColor "base0E");
    };
  };
}
