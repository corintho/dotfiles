{
  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        general = {
          border_size = 2;
          "col.active_border" = "0xff3c2bd0";
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
          "workspace name:Browsers, class:Vivaldi.*"
          "workspace name:Dev, class:neovide"
          "workspace name:Dev, class:kitty"
          "workspace name:cOmms, class:Proton Mail"
          "workspace special:magic, class:Proton Pass"
        ];
        "$mod" = "ALT";
        "$mod2" = "ALT_SHIFT";
        "$meh" = "ALT_CTRL_SHIFT";
        "$super" = "ALT_CTRL_SHIFT_SUPER";
        "$launcher" = "SUPER";
        "$terminal" = "kitty";
        "$browser" = "vivaldi";
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
                bind = $meh, LEFT, focusmonitor, -1
                bind = $meh, RIGHT, focusmonitor, +1
                bind = $super, LEFT, movewindow, mon:-1
        	      bind = $super, RIGHT, movewindow, mon:+1
                bind = $mod, TAB, workspace, previous
                bind = $mod2, TAB, movecurrentworkspacetomonitor, +1
                # Launcher
                bind = $launcher, B, exec, $browser
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
        	      # Service mode
      '';
    };
  };
}

