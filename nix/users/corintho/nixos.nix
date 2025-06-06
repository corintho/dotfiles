{ config, pkgs, pkgs-unstable, ... }:
let
  cifsOptions =
    "uid=1000,gid=100,x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
in {
  # SMB shares
  fileSystems."/smb/home" = {
    device = "//192.168.2.250/home";
    fsType = "cifs";
    options =
      [ "${cifsOptions},credentials=${config.age.secrets.smb_corintho.path}" ];
  };

  fileSystems."/smb/ai" = {
    device = "//192.168.2.250/ai";
    fsType = "cifs";
    options =
      [ "${cifsOptions},credentials=${config.age.secrets.smb_corintho.path}" ];
  };

  environment.systemPackages = with pkgs-unstable; [
    cryptomator
    cifs-utils
    samba
  ];

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

    fish = { enable = true; };
  };

  users.users.corintho = {
    uid = 1000;
    extraGroups = [ "input" ];
    shell = pkgs.fish;
  };
}
