{ config, ... }:
let inherit (config.lib.stylix) colors;
in {
  config = {
    services.xserver.windowManager.qtile = {
      enable = true;
      extraPackages = pyks: with pyks; [ qtile-extras ];
    };
  };
}

