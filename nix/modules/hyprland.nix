{ config, pkgs, ... }:
let inherit (config.lib.stylix) colors;
in {
  config = {
    home.packages = with pkgs; [
      unstable.wl-kbptr
      # Custom scripts on path
      (writeShellApplication {
        name = "h_switch_window_mode";
        text = ''
          hyprctl dispatch focuswindow "$(if [[ $(hyprctl activewindow -j | jq .'floating') == 'true' ]]; then echo 'tiled'; else echo 'floating'; fi;)"'';
      })
      # /Custom scripts on path
    ];
    xdg.configFile = {
      "wl-kbptr/config".text = ''
        [general]
        home_row_keys=arstneiolyu
        modes=floating
        # modes=tile,bisect

        [mode_tile]
        label_color=#${colors.base06}
        label_select_color=#${colors.base07}
        unselectable_bg_color=#${colors.base01}88
        selectable_bg_color=#${colors.base02}66
        selectable_border_color=#${colors.base0D}
        label_font_family=sans-serif
        #label_font_size=8 50% 100
        label_symbols=arstneiodhzxcgmqwfpyulbjvk

        [mode_floating]
        source=detect
        label_color=#${colors.base06}
        label_select_color=#${colors.base07}
        unselectable_bg_color=#${colors.base01}88
        selectable_bg_color=#${colors.base02}BB
        selectable_border_color=#${colors.base0D}
        label_font_family=JetBrainsMonoNL Nerd Font Propo
        # label_font_size=12 50% 100
        label_symbols=arstneiodhzxcgmqwfpyulbjvk

        [mode_bisect]
        label_color=#${colors.base06}
        label_font_size=20
        label_font_family=JetBrainsMonoNL Nerd Font Propo
        label_padding=12
        pointer_size=20
        pointer_color=#${colors.base0F}
        unselectable_bg_color=#${colors.base01}88
        even_area_bg_color=#${colors.base00}88
        even_area_border_color=#${colors.base0D}
        odd_area_bg_color=#${colors.base03}88
        odd_area_border_color=#${colors.base0D}
        history_border_color=#${colors.base0E}

        [mode_click]
        button=left

      '';
    };
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        general = {
          border_size = 2;
          # "col.active_border" = lib.mkForce "0xff3c2bd0";
        };
        cursor = { hide_on_key_press = true; };
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
          "workspace name:cOmms, class:Proton Mail"
          "workspace name:cOmms, class:org.telegram.desktop"
          "workspace name:Dev, class:neovide"
          "workspace name:Dev, class:kitty"
          "workspace name:Dev, class:com.mitchellh.ghostty"
          "workspace name:Gaming, class:steam"
          "workspace name:Gaming, class:heroic"
          "workspace name:Gaming, class:net.lutris.Lutris"
          "workspace name:Gaming, class:net.davidotek.pupgui2"
          "workspace name:Gaming, class:org.prismlauncher.PrismLauncher"
          "workspace special:magic, class:Proton Pass"
        ];
        "$mod" = "SUPER";
        "$mod2" = "ALT_SHIFT";
        "$meh" = "ALT_CTRL_SHIFT";
        "$hyper" = "ALT_CTRL_SHIFT_SUPER";
        "$launcher" = "SUPER";
        "$terminal" = "ghostty";
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
        bind = $launcher, R, submap, launcher
        bind = $launcher, H, exec, ~/.local/lib/waybar/keybinds_hint.sh
        bind = $launcher, K, killactive
        bind = $launcher, SPACE, exec, $menu
        bind = $launcher, L, exec, swaylock
        # Zooming around
        bind = $mod, Z, exec, wl-kbptr
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
        # Resize mode
        submap = resize
        bind = , escape, submap, reset
        # Launcher mode
        submap = launcher
        bind = , B, exec, $browser
        bind = , E, exec, telegram-desktop
        bind = , H, exec, heroic
        bind = , L, exec, lutris
        bind = , M, exec, proton-mail
        bind = , N, exec, prismlauncher
        bind = , P, exec, proton-pass
        bind = , Q, exec, protonup-qt
        bind = , S, exec, steam
        bind = , T, exec, $terminal
        bind = , escape, submap, reset
        bind = $launcher, escape, submap, reset
        # Service mode
        submap = service
        bind = , escape, submap, reset
      '';
    };
  };
}

