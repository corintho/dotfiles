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
      prefix = "ctrl+a"
      detach = "prefix+d"
      focus_pane_left = ["prefix+h", "prefix+left", "alt+shift+left"]
      focus_pane_down = ["prefix+j", "prefix+down"]
      focus_pane_up = ["prefix+k", "prefix+up"]
      focus_pane_right = ["prefix+l", "prefix+right", "alt+shift+right"]
      swap_pane_left = ["prefix+shift+h", "prefix+shift+left"]
      swap_pane_down = ["prefix+shift+j", "prefix+shift+down"]
      swap_pane_up = ["prefix+shift+k", "prefix+shift+up"]
      swap_pane_right = ["prefix+shift+l", "prefix+shift+right"]
      split_vertical = ["prefix+v"]
      new_tab = ["prefix+c", "alt+n"]
      previous_tab = ["prefix+p", "alt+left"]
      next_tab = ["prefix+n", "alt+right"]

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
