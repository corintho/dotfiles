{ pkgs, ... }:
let
  baseConfig = builtins.fromTOML (builtins.readFile ./aerospace/aerospace.toml);
  sketchybarBin = "${pkgs.sketchybar}/bin/sketchybar";
in {
  config = {
    programs.aerospace = {
      enable = true;
      launchd.enable = true;
      package = pkgs.unstable.aerospace;
      userSettings = baseConfig // {
        exec-on-workspace-change = [
          "/bin/bash"
          "-c"
          "${sketchybarBin} --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
        ];
      };
    };
  };
}
