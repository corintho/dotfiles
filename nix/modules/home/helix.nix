{ lib, pkgs, ... }: {
  config = {
    programs = {
      helix = {
        enable = true;
        package = pkgs.unstable.helix;
        settings = lib.mkForce {
          theme = "lcars";
          editor = { line-number = "relative"; };
        };
      };
    };
    xdg.configFile = {
      "helix/themes/lcars.toml".text = ''
        inherits = 'stylix'

        "ui.cursor.primary" = { fg = "base04", modifiers = ["reversed"] }
      '';
    };
  };
}
