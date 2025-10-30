{ lib, pkgs, ... }: {
  config = {
    programs = {
      helix = {
        enable = true;
        package = pkgs.unstable.helix;
        settings = lib.mkForce {
          theme = "lcars";
          editor = {
            # Editor appearance
            line-number = "relative";
            bufferline = "multiple";
            color-modes = true;
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            indent-guides = { render = true; };
            # Diagnostics
            end-of-line-diagnostics = "hint";
            inline-diagnostics = { cursor-line = "warning"; };
            # Usability tunings
            jump-label-alphabet = "ntesiroahdmgcxzlpufywqjbkv";
            # Input setup
            mouse = false;
          };
          keys = {
            normal = {
              space = {
                q = ":quit";
                Q = ":quit!";
                w = ":write";
                "," = "command_mode";
              };
              "]" = { b = ":buffer-next"; };
              "[" = { b = ":buffer-previous"; };
            };
          };
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
