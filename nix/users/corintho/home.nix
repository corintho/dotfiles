{ config, dotFiles, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ ../../home/core.nix ../../modules/hyprland.nix ../../modules/waybar.nix ];
  home.sessionVariables = { EDITOR = "nvim"; };
  home.packages = with pkgs; [
    htop
    jq
    libnotify
    pkgs-unstable.proton-pass
    pkgs-unstable.protonmail-desktop
    pkgs-unstable.vivaldi
    font-awesome
    psmisc
    # Gaming
    pkgs-unstable.prismlauncher
    # TODO:More nvim
    nixd
    nixfmt-classic
    deadnix
    statix
    # /nvim
  ];

  xsession = { numlock.enable = true; };

  dconf.settings = {
    "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
    "org/gnome/desktop/peripherals/keyboard" = { numlock-state = true; };
  };

  programs = {
    fzf = { enable = true; };

    git = {
      enable = true;
      userName = "Corintho Assunção";
      userEmail = "github@corintho.eu";
    };

    kitty = {
      font = {
        name = "FiraCode Nerd Font";
        size = 12;
      };
    };

    neovide = {
      enable = true;
      package = pkgs-unstable.neovide;
      settings = { fork = true; };
    };

    nnn = {
      enable = true;
      package = pkgs-unstable.nnn.override { withNerdIcons = true; };
    };

    oh-my-posh = {
      enable = true;
      settings = builtins.fromJSON (builtins.unsafeDiscardStringContext
        (builtins.readFile "${dotFiles}/custom.omp.json"));
    };

    ripgrep = { enable = true; };

    swaylock = {
      enable = true;
      settings = { color = "161429"; };
    };

    zoxide = { enable = true; };

    zsh = {
      enable = true;
      autocd = true;
      enableCompletion = true;
      history = {
        ignoreDups = true;
        ignoreSpace = true;
      };
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
      syntaxHighlighting = {
        enable = true;
        highlighters = [ "brackets" ];
      };
      shellAliases = {
        listening = "lsof -iTCP -sTCP:LISTEN -n -P";
        scripts = ''
          jq ".scripts | to_entries | sort_by(.key) | from_entries" package.json'';
        n = "neovide";
      };
    };
  };

  services = {
    swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = "${pkgs.swaylock}/bin/swaylock -fF";
        }
        {
          event = "lock";
          command = "lock";
        }
      ];
      timeouts = [
        {
          timeout = 290;
          command =
            "${pkgs.libnotify}/bin/notify-send 'Locking in 10 seconds' -t 10000";
        }
        {
          timeout = 300;
          command = "${config.programs.swaylock.package}/bin/swaylock -fF";
        }
        {
          timeout = 600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };

    swaync = { enable = true; };
  };
}
