{ lcars, lib, ... }:
{
  config = {
    xdg.configFile."herdr/config.toml".text = ''
      # Mirrors this machine's zellij config (nix/modules/home/zellij/config.kdl) as
      # closely as herdr's prefix-based keybinding model allows.

      # Skip herdr's first-run onboarding flow; matches zellij's
      # show_startup_tips false / show_release_notes false.
      onboarding = false

      [theme]
      name = "one-dark"

      [keys]
      # zellij: `locked { bind "Ctrl a" { SwitchToMode "normal"; } }` -- Ctrl+a is
      # zellij's mode-toggle key. Herdr's prefix is transient (press once, then one
      # action key) rather than a sticky mode toggle, but it intercepts the chord the
      # same way zellij already does -- no new shell/readline behavior is lost.
      prefix = "ctrl+a"
      # zellij: session-mode `bind "d" { Detach; }` (herdr default: prefix+q).
      detach = "prefix+d"
      # zellij binds both arrows and hjkl to pane focus/move; this user navigates
      # with arrows, so both are bound here, plus the global Alt+arrow chords zellij
      # exposes without any prefix (confirmed working on this terminal).
      focus_pane_left = ["prefix+h", "prefix+left", "alt+left"]
      focus_pane_down = ["prefix+j", "prefix+down", "alt+down"]
      focus_pane_up = ["prefix+k", "prefix+up", "alt+up"]
      focus_pane_right = ["prefix+l", "prefix+right", "alt+right"]
      swap_pane_left = ["prefix+shift+h", "prefix+shift+left"]
      swap_pane_down = ["prefix+shift+j", "prefix+shift+down"]
      swap_pane_up = ["prefix+shift+k", "prefix+shift+up"]
      swap_pane_right = ["prefix+shift+l", "prefix+shift+right"]
      split_vertical = ["prefix+v", "alt+n"]
      # Every other action already defaults to the closest zellij analog once the
      # prefix above changes, and is intentionally left unset:
      #   cycle_pane_{next,previous}        prefix+tab(+shift) zellij pane-mode "tab" (SwitchFocus)
      #   split_horizontal                  prefix+minus       zellij pane-mode NewPane "down"
      #   close_pane                        prefix+x           zellij pane-mode CloseFocus
      #   zoom                              prefix+z           zellij ToggleFocusFullscreen
      #   resize_mode                       prefix+r           zellij resize-mode entry "r"
      #   edit_scrollback                   prefix+e           zellij scroll-mode "e"
      #   copy_mode                         prefix+[           zellij scroll+entersearch+search modes combined
      #   new_tab                           prefix+c           zellij tab-mode "n" ("n" is taken by next_tab)
      #   previous_tab / next_tab           prefix+p / prefix+n zellij tab-mode arrow/hjkl cycling (no arrow
      #                                                         alias here -- prefix+left/right already mean
      #                                                         focus_pane_left/right above)
      #   switch_tab                        prefix+1..9        zellij tab-mode "1".."9"
      #   workspace_picker                  prefix+w           zellij session-mode "w" (session-manager)
      # Not overridden -- herdr has no action to reassign them to: zellij's tab-mode
      # sync-tab ("s"), break-pane ("[", "]", "b"), and resize mode's non-directional
      # +/-/= grow/shrink have no herdr analog. zellij's global Ctrl+q (Quit, kills
      # the whole session) has no herdr analog either: herdr's server is
      # always-running by design; `herdr server stop` fully stops it from the CLI.

      # zellij: `serialize_pane_viewport true` -- replay recent pane screen contents
      # after a full herdr server restart (detach/reattach already preserves
      # everything, since the server process never stops). Pane output can include
      # secrets/tokens; herdr writes it to ~/.config/herdr/session-history.json.
      [experimental]
      pane_history = true

      # Preserved from settings already configured through herdr's own Settings UI
      # (unrelated to zellij parity).
      [ui.toast]
      delivery = "terminal"

      [ui]
      show_agent_labels_on_pane_borders = true
      status_indicators = "symbols"
    ''
    + lib.optionalString lcars.shell.fish.enable ''

      [terminal]
      default_shell = "${lcars.shell.fish.package}/bin/fish"
    '';
  };
}
