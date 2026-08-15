{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Install gdu into the user environment (NixOS + Darwin home-manager).
  home.packages = [ pkgs.gdu ];

  # Take over gdu styling manually. stylix's generated theme sets
  # result-row.directory-color to base02 (#2c313a) on a black background,
  # painting folder names black-on-black. Repaint directories in blue
  # (base0D, ls-like) while staying theme-aware across NixOS and Darwin.
  stylix.targets.gdu.enable = false;

  xdg.configFile."gdu/gdu.yaml" = {
    enable = true;
    text = with config.lib.stylix.colors.withHashtag; ''
      style:
        selected-row:
          text-color: "${base0A}"
          background-color: "${base00}"
        result-row:
          number-color: "${base06}"
          directory-color: "${base0D}"
        footer:
          text-color: "${base05}"
          background-color: "${base00}"
          number-color: "${base06}"
        header:
          text-color: "${base05}"
          background-color: "${base00}"
    '';
  };
}
