{ config, dotFiles, pkgs, pkgs-unstable, rootPath, ... }:

{
  imports = [
    ../../home/core.nix
    ../../modules/hyprland.nix
    ../../modules/waybar.nix
    ../../modules/hyprpaper.nix
  ];
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
    vlc
    # Gaming
    pkgs-unstable.prismlauncher
    # TODO:More nvim
    nixd
    nixfmt-classic
    deadnix
    statix
    # /nvim
    # Terminal tools
    fd
    bat
    tlrc
    # /Terminal tools
    # Coding tools
    devenv
    # /Coding tools
    # Screen capturing
    hyprshot
    grim
    slurp
    # /Screen capturing
  ];

  home.file = {
    # TODO: Make the folder reference dynamic through a variable
    ".local/share/wallpapers/" = {
      source = rootPath + /wallpapers;
      recursive = true;
    };
  };

  xsession = { numlock.enable = true; };

  dconf.settings = {
    "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
    "org/gnome/desktop/peripherals/keyboard" = { numlock-state = true; };
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    eza = {
      enable = true;
      colors = "auto";
      git = true;
      icons = "auto";
    };

    fzf = { enable = true; };

    git = {
      enable = true;
      userName = "Corintho Assunção";
      userEmail = "github@corintho.eu";
      difftastic = {
        enable = true;
        enableAsDifftool = true;
        display = "inline";
        package = pkgs-unstable.difftastic;
      };
      extraConfig = {
        difftool = { prompt = false; };
        pager = { difftool = true; };
      };
    };

    kitty = {
      font = {
        name = "FiraCode Nerd Font";
        size = 12;
      };
    };

    mpv = {
      enable = true;
      package = pkgs-unstable.mpv;
    };

    neovide = {
      enable = true;
      package = pkgs-unstable.neovide;
      settings = { fork = true; };
    };

    oh-my-posh = {
      enable = true;
      settings = builtins.fromJSON (builtins.unsafeDiscardStringContext
        (builtins.readFile "${dotFiles}/custom.omp.json"));
    };

    ripgrep = { enable = true; };

    swaylock = {
      enable = true;
      settings = {
        color = "161429";
        # TODO: Make the folder reference dynamic through a variable
        image = "~/.local/share/wallpapers/973571.jpg";
      };
    };

    yazi = {
      enable = true;
      settings = {
        manager = {
          show_hidden = true;
          sort_by = "natural";
        };
        preview = {
          max_width = 1600;
          max_height = 1000;
        };
      };
      package = pkgs-unstable.yazi;
      shellWrapperName = "y";
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
