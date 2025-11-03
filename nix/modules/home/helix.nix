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
              "C-," = "command_mode";
              "C-e" = [
                ":sh rm -f /tmp/files2open"
                ''
                  :insert-output yazi "%{buffer_name}" --chooser-file=/tmp/files2open''
                ":redraw"
                ":open /tmp/files2open"
                "select_all"
                "split_selection_on_newline"
                "goto_file"
                ":buffer-close! /tmp/files2open"
              ];
              "C-g" =
                [ ":new" ":insert-output lazygit" ":buffer-close!" ":redraw" ];
              space = {
                c = ":buffer-close";
                q = ":quit";
                Q = ":quit!";
                w = ":write";
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
