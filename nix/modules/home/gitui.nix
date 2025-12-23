{ pkgs, ... }:
{
  programs.gitui = {
    enable = true;
    package = pkgs.unstable.gitui;
    keyConfig = ''
      commit_amend: Some(( code: Char('g'), modifiers: "CONTROL")),
    '';
  };
}
