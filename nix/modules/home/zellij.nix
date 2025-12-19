{ config, lcars, lib, pkgs, ... }:
let inherit (config.lib.stylix) colors;
in {
  config = {

    xdg.configFile = {
      "zellij/plugins/zellij_forgot.wasm".source = pkgs.fetchurl {
        url =
          "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
        sha256 = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
      };
      "zellij/layouts" = {
        source = ./zellij/layouts;
        recursive = true;
      };
      "zellij/plugins/zjstatus.wasm".source = pkgs.fetchurl {
        url =
          "https://github.com/dj95/zjstatus/releases/download/v0.22.0/zjstatus.wasm";
        sha256 = "sha256-TeQm0gscv4YScuknrutbSdksF/Diu50XP4W/fwFU3VM=";
      };
      "zellij/plugins/zjstatus-hints.wasm".source = pkgs.fetchurl {
        url =
          "https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm";
        sha256 = "sha256-k2xV6QJcDtvUNCE4PvwVG9/ceOkk+Wa/6efGgr7IcZ0=";
      };
      "zellij/themes/lcars.kdl".source = colors {
        template = ./zellij/lcars.theme.mustache;
        extension = "kdl";
      };
      "zellij/config.kdl".text = builtins.readFile ./zellij/config.kdl
        + lib.concatStringsSep "\n" ([''

          // Plugin aliases - can be used to change the implementation of Zellij
          // changing these requires a restart to take effect
          plugins {
              about location="zellij:about"
              compact-bar location="zellij:compact-bar" {
                tooltip "Ctrl h"
              }
              configuration location="zellij:configuration"
              filepicker location="zellij:strider" {
                  cwd "/"
              }
              plugin-manager location="zellij:plugin-manager"
              session-manager location="zellij:session-manager"
              status-bar location="zellij:status-bar"
              strider location="zellij:strider"
              tab-bar location="zellij:tab-bar"
              welcome-screen location="zellij:session-manager" {
                  welcome_screen true
              }
              zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus-hints.wasm" {
                // Maximum number of characters to display
                max_length 0 // 0 = unlimited
                // String to append when truncated
                overflow_str "..." // default
                // Name of the pipe for zjstatus integration
                pipe_name "zjstatus_hints" // default
                // Hide hints in base mode (a.k.a. default mode)
                // E.g. if you have set default_mode to "locked", then
                // you can hide hints in the locked mode by setting this to true
                hide_in_base_mode false // default
              }
              zellij_forgot location="file:~/.config/zellij/plugins/zellij_forgot.wasm" {

              }
              zjstatus location="file:~/.config/zellij/plugins/zjstatus.wasm" {
                      color_bg "${colors.base03}"

                      format_left   "{mode}#[bg=#${colors.base00}] {tabs}"
                      format_center "{pipe_zjstatus_hints}" // A lot of potential, but needs more customization options
                      // format_center ""
           
                      format_right  "#[bg=#${colors.base00},fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base01},bold] #[bg=#${colors.base02},fg=#${colors.base05},bold] {session}#[bg=#${colors.base00},fg=#${colors.base02},bold]"
                      format_space  ""
                      format_hide_on_overlength "true"
                      format_precedence "rlc"

                      border_enabled  "false"
                      border_char     "─"
                      border_format   "#[fg=#6C7086]{char}"
                      border_position "top"

                      mode_normal        "#[fg=#${colors.base0B}]#[bg=#${colors.base0B},fg=#${colors.base02},bold]NORMAL#[fg=#${colors.base0B}]"
                      mode_locked        "#[fg=#${colors.base04}]#[bg=#${colors.base04},fg=#${colors.base02},bold]LOCKED  #[fg=#${colors.base04}]"
                      mode_resize        "#[fg=#${colors.base08}]#[bg=#${colors.base08},fg=#${colors.base02},bold]RESIZE#[fg=#${colors.base08}]"
                      mode_pane          "#[fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]PANE#[fg=#${colors.base0D}]"
                      mode_tab           "#[fg=#${colors.base07}]#[bg=#${colors.base07},fg=#${colors.base02},bold]TAB#[fg=#${colors.base07}]"
                      mode_scroll        "#[fg=#${colors.base0A}]#[bg=#${colors.base0A},fg=#${colors.base02},bold]SCROLL#[fg=#${colors.base0A}]"
                      mode_enter_search  "#[fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]ENT-SEARCH#[fg=#${colors.base0D}]"
                      mode_search        "#[fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]SEARCHARCH#[fg=#${colors.base0D}]"
                      mode_rename_tab    "#[fg=#${colors.base07}]#[bg=#${colors.base07},fg=#${colors.base02},bold]RENAME-TAB#[fg=#${colors.base07}]"
                      mode_rename_pane   "#[fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]RENAME-PANE#[fg=#${colors.base0D}]"
                      mode_session       "#[fg=#${colors.base0E}]#[bg=#${colors.base0E},fg=#${colors.base02},bold]SESSION#[fg=#${colors.base0E}]"
                      mode_move          "#[fg=#${colors.base0F}]#[bg=#${colors.base0F},fg=#${colors.base02},bold]MOVE#[fg=#${colors.base0F}]"
                      mode_prompt        "#[fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]PROMPT#[fg=#${colors.base0D}]"

                      // formatting for inactive tabs
                      tab_normal              "#[bg=#${colors.base00},fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base00},fg=#${colors.base02},bold]"
                      tab_normal_fullscreen   "#[bg=#${colors.base00},fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base00},fg=#${colors.base02},bold]"
                      tab_normal_sync         "#[bg=#${colors.base00},fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base00},fg=#${colors.base02},bold]"

                      // formatting for the current active tab
                      tab_active              "#[bg=#${colors.base00},fg=#${colors.base09}]#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base00},fg=#${colors.base02},bold]"
                      tab_active_fullscreen   "#[bg=#${colors.base00},fg=#${colors.base09}]#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base00},fg=#${colors.base02},bold]"
                      tab_active_sync         "#[bg=#${colors.base00},fg=#${colors.base09}]#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base00},fg=#${colors.base02},bold]"

                      // separator between the tabs
                      tab_separator           "#[bg=#${colors.base00}] "

                      // indicators
                      tab_sync_indicator       "  "
                      tab_fullscreen_indicator " 󰊓 "
                      tab_floating_indicator   " 󰹙 "

                      command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                      command_git_branch_format      "#[fg=blue] {stdout} "
                      command_git_branch_interval    "10"
                      command_git_branch_rendermode  "static"

                      datetime        "#[fg=#6C7086,bold] {format} "
                      datetime_format "%A, %d %b %Y %H:%M"
                      datetime_timezone "Europe/Amsterdam"
                      // Note: this is necessary or else zjstatus won't render the pipe:
                      pipe_zjstatus_hints_format "{output}"
                  }
          }

          // Plugins to load in the background when a new session starts
          // eg. "file:/path/to/my-plugin.wasm"
          // eg. "https://example.com/my-plugin.wasm"
          load_plugins {
              zjstatus
              zjstatus-hints
          }

          // Our custom theme
          theme "lcars"
        '']
          ++ (lib.optional (lcars.shell.fish.enable) ''default_shell "fish"''));
    };

    programs = {
      zellij = {
        enable = true;
        package = pkgs.unstable.zellij;
      };

      fish = {
        interactiveShellInit =
          "${config.programs.zellij.package}/bin/zellij setup --generate-completion fish | source";
      };
      zsh = {
        initContent = lib.mkAfter ''
          # Add zellij complete and aliases
          source ${./zellij/zellij.zsh}'';
      };
    };
  };
}
