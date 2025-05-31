{ pkgs-unstable, ... }: {

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs-unstable.appimage-run.override {
        extraPkgs = pkgs-unstable:
          with pkgs-unstable; [
            icu
            libxcrypt-legacy
            python312
            python312Packages.torch
          ];
      };
    };

    bazecor = {
      enable = true;
      package = pkgs-unstable.bazecor;
    };
  };

  users.users.corintho = {
    uid = 1000;
    extraGroups = [ "input" ];
  };
}
