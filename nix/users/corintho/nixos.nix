{ config, lib, pkgs, ... }:
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

  environment.systemPackages = with pkgs.unstable; [
    cryptomator
    cifs-utils
    lsof
    samba
    # Gaming
    mangohud
    protonup-qt
    lutris
    bottles
    heroic
    itch
  ];

  # Global aliases for all shells
  environment.shellAliases = {
    listening = "lsof -iTCP -sTCP:LISTEN -n -P";
    scripts = ''
      jq ".scripts | to_entries | sort_by(.key) | from_entries" package.json'';
    n = "nvim";
    gitskipped = "git ls-files -v|grep '^S'";
    gitskip = "git update-index --skip-worktree";
    gitunskip = "git update-index --no-skip-worktree";
    #TODO: Remove this when freecad support wayland better
    freecad = "QT_QPA_PLATFORM=xcb command freecad";
  };

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.unstable.appimage-run.override {
        extraPkgs = _:
          with pkgs.unstable; [
            icu
            libxcrypt-legacy
            python312Full
            python312Packages.torch
          ];
      };
    };

    bazecor = {
      enable = true;
      package = pkgs.unstable.bazecor;
    };

    fish = { enable = config.lcars.shell.fish.enable; };

    # Gaming
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      package = pkgs.unstable.steam;
    };
    gamemode = { enable = true; };
  };

  users.users.corintho = lib.mkMerge [
    {
      uid = 1000;
      extraGroups = [ "input" ];
    }
    (lib.mkIf config.lcars.shell.fish.enable {
      shell = config.lcars.shell.fish.pkg;
    })
  ];
}
