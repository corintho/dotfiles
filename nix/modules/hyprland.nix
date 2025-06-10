{ pkgs, ... }: {
  config = {
    home.packages = with pkgs;
      [
        # Custom scripts on path
        (writeShellApplication {
          name = "h_switch_window_mode";
          text = ''
            hyprctl dispatch focuswindow "$(if [[ $(hyprctl activewindow -j | jq .'floating') == 'true' ]]; then echo 'tiled'; else echo 'floating'; fi;)"'';
        })
        # /Custom scripts on path
      ];
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        general = {
          border_size = 2;
          # "col.active_border" = lib.mkForce "0xff3c2bd0";
        };
        decoration = { rounding = 10; };
        input = {
          kb_layout = "us, us";
          kb_variant = ", intl";
          kb_options = "grp:menu_toggle";
          numlock_by_default = true;
        };
        monitor = [
          "DP-3,1920x1080@119.98,0x0,1"
          "HDMI-A-1,1920x1080@60,auto-right,1"
        ];
        # Only needed when going through logs to debug issues
        # debug = { disable_logs = false; };
        # Remember to update waybar settings to match
        workspace = [
          "name:Misc,monitor:DP-3,default:true"
          "name:Browsers,monitor:HDMI-A-1,default:true"
          "name:cOmms"
          "name:Dev"
          "name:Gaming"
        ];
        windowrulev2 = [
          "workspace name:Browsers, class:zen"
          "workspace name:Dev, class:neovide"
          "workspace name:Dev, class:kitty"
          "workspace name:cOmms, class:Proton Mail"
          "workspace special:magic, class:Proton Pass"
        ];
        "$mod" = "SUPER";
        "$mod2" = "ALT_SHIFT";
        "$meh" = "ALT_CTRL_SHIFT";
        "$hyper" = "ALT_CTRL_SHIFT_SUPER";
        "$launcher" = "SUPER";
        "$terminal" = "kitty";
        "$browser" = "zen";
        "$menu" = "rofi -show drun";
      };
      extraConfig = ''
        	      # Global submap
                submap = reset
        	      # Focusing
                bind = $mod, left, movefocus, l
                bind = $mod, right, movefocus, r
                bind = $mod, up, movefocus, u
                bind = $mod, down, movefocus, d
        	      # Moving
                bind = $mod2, left, movewindow, l
                bind = $mod2, right, movewindow, r
                bind = $mod2, up, movewindow, u
                bind = $mod2, down, movewindow, d
        	      # Resizing
        	      # Layouting
                bind = $mod, F, fullscreen
                bind = $mod2, F, togglefloating
                bind = $mod2, T, exec, h_switch_window_mode
                bind = $meh, LEFT, focusmonitor, -1
                bind = $meh, RIGHT, focusmonitor, +1
                bind = $hyper, LEFT, movewindow, mon:-1
                bind = $hyper, RIGHT, movewindow, mon:+1
                bind = $mod, TAB, workspace, previous
                bind = $mod2, TAB, movecurrentworkspacetomonitor, +1
                # Launcher
                bind = $launcher, R, exec, $browser
                bind = $launcher, T, exec, $terminal
                bind = $launcher, K, killactive
                bind = $launcher, SPACE, exec, $menu
                bind = $launcher, L, exec, swaylock
        	      # Workspaces
                bind = $mod, B, workspace, name:Browsers
                bind = $mod2, B, movetoworkspace, name:Browsers
                bind = $mod, O, workspace, name:cOmms
                bind = $mod2, O, movetoworkspace, name:cOmms
                bind = $mod, D, workspace, name:Dev
                bind = $mod2, D, movetoworkspace, name:Dev
                bind = $mod, G, workspace, name:Gaming
                bind = $mod2, G, movetoworkspace, name:Gaming
                bind = $mod, M, workspace, name:Misc
                bind = $mod2, M, movetoworkspace, name:Misc
                bind = $mod, S, togglespecialworkspace, magic
                bind = $mod2, S, movetoworkspace, special:magic
                # Screenshots
                bind = $hyper, S, exec, hyprshot -m region --clipboard-only
                # Volume control
                binde = , XF86AudioRaiseVolume, exec, pamixer --increase 5
                binde = , XF86AudioLowerVolume, exec, pamixer --decrease 5
                bind = , XF86AudioMute, exec, pamixer --toggle-mute
        	      # Service mode
      '';
    };
  };
}

