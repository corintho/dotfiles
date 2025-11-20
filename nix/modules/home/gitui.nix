{ pkgs, ... }:
{
  # extra packages for niri
  home.packages = with pkgs; [ gitui ];

  xdg.configFile = {
    "gitui/key_bindings.ron".text = ''
      (
          commit_amend: Some(( code: Char('g'), modifiers: "CONTROL")),
      )
    '';
  };
}
