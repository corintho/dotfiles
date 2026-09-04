{ config, ... }:
let
  inherit (config.lib.stylix) colors;
in
{
  config = {
    xdg.configFile."herdr/config.toml".text = ''
      # Herdr "obsidian" theme override, derived from the active stylix base16Scheme.
      # 17 of 19 tokens track the active scheme automatically; two (selection_bg,
      # subtext0) have no base16 equivalent and stay hardcoded to oh-my-pi's
      # original obsidian.json values ("dim"/"syntaxOperator") -- they will not
      # re-theme if the active base16Scheme is ever switched away from obsidian.
      [theme]
      name = "terminal"

      [theme.custom]
      accent = "#${colors.base0E}"
      panel_bg = "#${colors.base00}"
      sidebar_bg = "#${colors.base01}"
      active_row_bg = "#${colors.base02}"
      # No base16 slot for this -- oh-my-pi obsidian.json's "dim" token, not portable across schemes.
      selection_bg = "#4a4642"
      surface0 = "#${colors.base01}"
      surface1 = "#${colors.base02}"
      surface_dim = "#${colors.base00}"
      overlay0 = "#${colors.base03}"
      overlay1 = "#${colors.base04}"
      text = "#${colors.base05}"
      # No base16 slot for this -- oh-my-pi obsidian.json's "syntaxOperator" token, not portable across schemes.
      subtext0 = "#b8b4af"
      mauve = "#${colors.base0E}"
      green = "#${colors.base0B}"
      yellow = "#${colors.base09}"
      red = "#${colors.base08}"
      blue = "#${colors.base0D}"
      teal = "#${colors.base0C}"
      peach = "#${colors.base0F}"
    '';
  };
}
