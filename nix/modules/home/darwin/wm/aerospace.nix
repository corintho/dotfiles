{ pkgs, username, ... }:
let
  baseConfig = builtins.fromTOML (builtins.readFile ./aerospace/aerospace.toml);
  sketchybarBin = "${pkgs.sketchybar}/bin/sketchybar";
  aerospaceBin = "${pkgs.unstable.aerospace}/bin/aerospace";
  watchdogScript = pkgs.writeShellScript "aerospace-watchdog" ''
    LOG="/Users/${username}/Library/Logs/aerospace-watchdog.log"
    if ! ${pkgs.coreutils}/bin/timeout 5 ${aerospaceBin} list-workspaces --all > /dev/null 2>&1; then
      echo "$(date -Iseconds): AeroSpace was unresponsive, killing..." >> "$LOG"
      pkill -x AeroSpace || true
    fi
  '';
in
{
  config = {
    programs.aerospace = {
      enable = true;
      launchd.enable = true;
      package = pkgs.unstable.aerospace;
      settings = baseConfig // {
        exec-on-workspace-change = [
          "/bin/bash"
          "-c"
          "${sketchybarBin} --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
        ];
      };
    };

    launchd.agents."aerospace-watchdog" = {
      enable = true;
      config = {
        ProgramArguments = [ "${watchdogScript}" ];
        StartInterval = 10;
        RunAtLoad = false;
        StandardOutPath = "/Users/${username}/Library/Logs/aerospace-watchdog.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/aerospace-watchdog.log";
      };
    };
  };
}
