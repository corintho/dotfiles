{ config, lib, ... }: {
  options.custom.menuBar = {
    autoHide = lib.mkOption {
      type = lib.types.nullOr
        (lib.types.enum [ "always" "desktop-only" "fullscreen-only" "never" ]);
      default = null;
      description = ''
        Control macOS menu bar auto-hide behavior.

        - `always`: Menu bar hidden, reveals on hover (value: 0)
        - `desktop-only`: Auto-hide on desktop, always visible in fullscreen (value: 1)
        - `fullscreen-only`: Always visible on desktop, hidden in fullscreen (value: 2)
        - `never`: Menu bar always visible (value: 3)
      '';
    };
  };

  config = let
    autoHideMap = {
      always = 0;
      "desktop-only" = 1;
      "fullscreen-only" = 2;
      never = 3;
    };
    autoHideValue = autoHideMap.${config.custom.menuBar.autoHide};
  in lib.mkIf (config.custom.menuBar.autoHide != null) {
    system.defaults = {
      CustomUserPreferences."com.apple.controlcenter".AutoHideMenuBarOption =
        autoHideValue;
      NSGlobalDomain._HIHideMenuBar =
        (autoHideValue == 0 || autoHideValue == 1);
    };
  };
}
