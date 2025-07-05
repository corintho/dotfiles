{
  programs.rofi = {
    enable = true;
    modes = [ "window" "run" "drun" "ssh" "pwrctl" ];
  };

  xdg.configFile = {
    "rofi/scripts/pwrctl.sh" = {
      source = ./rofi/pwrctl.sh;
      executable = true;
    };
  };
}

