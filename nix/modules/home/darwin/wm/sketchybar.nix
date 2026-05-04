{ config, pkgs, ... }: {
  config = {
    # Create sketchybarrc with absolute Nix store paths for lua5.4 and sbarlua
    programs.sketchybar = {
      enable = true;
      package = let
        # Extract Lua package that sbarlua was built with
        lua = builtins.head pkgs.sbarlua.propagatedBuildInputs;
        luaVersion = lua.luaversion;
      in pkgs.writeShellScriptBin "sketchybar" ''
        export PATH="${lua}/bin:${pkgs.unstable.aerospace}/bin:$HOME/.config/sketchybar/helpers/event_providers/bin:$HOME/.config/sketchybar/helpers/menus/bin:$PATH"
        export LUA_CPATH="${pkgs.sbarlua}/lib/lua/${luaVersion}/?.so''${LUA_CPATH:+:$LUA_CPATH}"
        export CONFIG_DIR="$HOME/.config/sketchybar"
        exec ${pkgs.unstable.sketchybar}/bin/sketchybar "$@"
      '';
      config = let
        inherit (config.lib.stylix) colors;

        # Extract Lua package that sbarlua was built with
        lua = builtins.head pkgs.sbarlua.propagatedBuildInputs;
        luaVersion = lua.luaversion;

        # Alpha channel constants for SketchyBar colors (0x00 - 0xff)
        alphaBarBackground = "f0"; # 94% opacity for bar background
        alphaPopupBackground = "c0"; # 75% opacity for popup background
        alphaFullyOpaque = "ff"; # 100% opacity
        alphaTransparent = "00"; # 0% opacity

        # Helper to convert stylix hex (without #) to SketchyBar format (0xAARRGGBB)
        toSketchyBarColor = hexColor: alpha: "0x${alpha}${hexColor}";

        # Create sketchybarrc as a Nix derivation with hardcoded paths
        sketchybarrc = pkgs.writeScript "sketchybarrc" ''
          #!${lua}/bin/lua

          -- Require the sketchybar module (installed via Nix from pkgs.sbarlua)
          package.cpath = "${pkgs.sbarlua}/lib/lua/${luaVersion}/?.so;" .. package.cpath

          sbar = require("sketchybar")

          -- Bundle the entire initial configuration into a single message to sketchybar
          -- This improves startup times drastically
          sbar.begin_config()
          require("helpers")
          require("init")
          sbar.hotload(true)
          sbar.end_config()

          -- Run the event loop of the sketchybar module (without this there will be no
          -- callback functions executed in the lua module)
          sbar.event_loop()
        '';

        # Generate colors.lua from current stylix theme
        colorsLua = pkgs.writeText "colors.lua" ''
          -- DO NOT EDIT. Auto-generated from current stylix theme during deploy.
          -- Colors will sync with system theme changes via stylix.

          return {
            black = ${toSketchyBarColor colors.base00 alphaFullyOpaque},
            white = ${toSketchyBarColor colors.base07 alphaFullyOpaque},
            red = ${toSketchyBarColor colors.base08 alphaFullyOpaque},
            green = ${toSketchyBarColor colors.base0B alphaFullyOpaque},
            blue = ${toSketchyBarColor colors.base0D alphaFullyOpaque},
            yellow = ${toSketchyBarColor colors.base0A alphaFullyOpaque},
            orange = ${toSketchyBarColor colors.base09 alphaFullyOpaque},
            magenta = ${toSketchyBarColor colors.base0E alphaFullyOpaque},
            grey = ${toSketchyBarColor colors.base03 alphaFullyOpaque},
            transparent = 0x${alphaTransparent}000000,

            bar = {
              bg = ${toSketchyBarColor colors.base01 alphaBarBackground},
              border = ${toSketchyBarColor colors.base01 alphaFullyOpaque},
            },
            popup = {
              bg = ${toSketchyBarColor colors.base01 alphaPopupBackground},
              border = ${toSketchyBarColor colors.base03 alphaFullyOpaque},
            },
            bg1 = ${toSketchyBarColor colors.base01 alphaFullyOpaque},
            bg2 = ${toSketchyBarColor colors.base02 alphaFullyOpaque},

            with_alpha = function(color, alpha)
              if alpha > 1.0 or alpha < 0.0 then
                return color
              end
              return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
            end,
          }
        '';

        # Create a directory with sketchybarrc and all other lua files
        sketchybar-config = pkgs.runCommand "sketchybar-config" { } ''
          mkdir -p $out
          cp ${sketchybarrc} $out/sketchybarrc
          chmod +x $out/sketchybarrc
          cp -r ${./sketchybar}/* $out/
          # Replace colors.lua with generated one from stylix theme
          cp ${colorsLua} $out/colors.lua
          # Remove any old sketchybarrc if it exists
          rm -f $out/sketchybarrc.lua
        '';
      in {
        source = sketchybar-config;
        recursive = true;
      };
    };
  };
}

