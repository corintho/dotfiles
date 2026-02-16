{ config, lcars, inputs, lib, pkgs, ... }:

let
  fishModule = ../../modules/home/fish.nix;
  orcaApp = pkgs.callPackage ../../modules/orca-slicer.nix { };
  freecadRCApp = pkgs.callPackage ../../modules/freecad-rc.nix { };
in {
  imports = [
    inputs.agenix.homeManagerModules.default
    ../../home/core.nix
    ../../modules/home/user_secrets.nix
    ../../modules/home/ghostty.nix
    ../../modules/home/gitui.nix
    ../../modules/home/helix.nix
    ../../modules/home/hyprland.nix
    ../../modules/home/hyprpaper.nix
    ../../modules/home/niri.nix
    ../../modules/home/neovim.nix
    ../../modules/home/oh_my_posh.nix
    ../../modules/home/opencode.nix
    # ../../modules/home/qtile.nix
    ../../modules/home/rofi.nix
    ../../modules/home/waybar.nix
    ../../modules/home/zed.nix
    ../../modules/home/zellij.nix
  ] ++ (lib.optional lcars.shell.fish.enable fishModule);
  home.packages = with pkgs; [
    htop
    jq
    libnotify
    unstable.proton-pass
    unstable.protonmail-desktop
    unstable.vivaldi
    unstable.telegram-desktop
    font-awesome
    psmisc
    vlc
    mediainfo
    exiftool
    p7zip
    file-roller
    libreoffice
    kdePackages.okular
    unstable.lazygit
    # Gaming
    prismlauncher
    unstable.discord
    # 3D printing
    orcaApp
    # AI
    unstable.alpaca
    unstable.ollama
    # unstable.oterm
    # Terminal tools
    fd
    bat
    tlrc
    # /Terminal tools
    # Coding tools
    unstable.devenv
    # /Coding tools
    # Screen capturing
    hyprshot
    grim
    slurp
    # /Screen capturing
    # Freecad
    freecadRCApp
    # freecad
    # (writeShellApplication {
    #   name = "freecad-fixed";
    #   text = ''QT_QPA_PLATFORM=xcb command ${freecad}/bin/freecad "$@"'';
    # })
    # /Freecad
    unstable.obsidian
    # Sweet home 3d
    unstable.sweethome3d.application
    unstable.sweethome3d.textures-editor
    unstable.sweethome3d.furniture-editor
    (writeShellApplication {
      name = "sweethome3d-fixed";
      text = ''
        JAVA_TOOL_OPTIONS="-Dcom.eteks.sweethome3d.j3d.useOffScreen3DView=true" ${unstable.sweethome3d.application}/bin/sweethome3d "$@"'';
    })
    # /Sweet home 3d
    # Music
    unstable.musescore
    # Custom scripts on path
    (writeShellApplication {
      name = "windows_junctions";
      text = builtins.readFile ./scripts/windows_junctions;
    })
    # /Custom scripts on path
  ];

  # Custom launcher for "fixed" apps
  xdg.desktopEntries = {
    # freecad = {
    #   type = "Application";
    #   name = "Freecad (fixed)";
    #   exec = "freecad-fixed";
    #   icon = "freecad";
    #   categories = [ "Utility" ];
    # };
    sweethome-3d = {
      type = "Application";
      name = "Sweethome-3d (fixed)";
      exec = "sweethome3d-fixed";
      icon = "sweethome3d";
      categories = [ "Utility" ];
    };
  };

  home.sessionVariables = { EDITOR = "hx"; };
  home.sessionVariables = { OLLAMA_MODELS = "/windows/e/__Slow_AI_E/ollama"; };
  xsession = { numlock.enable = true; };

  dconf.settings = {
    "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
    "org/gnome/desktop/peripherals/keyboard" = { numlock-state = true; };
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-battery-type = "nothing";
      sleep-inactive-battery-timeout = 0;
    };
  };

  # Disable modules to handle their style manually
  stylix = {
    targets = {
      # Some apps do not behave correctly with GTK theming enabled
      gtk.enable = false;
      waybar.enable = false;
    };
  };

  programs = {
    bat = { enable = true; };

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
      settings = {
        user = {
          name = "Corintho Assunção";
          email = "github@corintho.eu";
        };
        difftool = { prompt = false; };
        pager = { difftool = true; };
      };
    };

    difftastic = {
      enable = true;
      options = {
        enableAsDifftool = true;
        display = "inline";
      };
      package = pkgs.unstable.difftastic;
    };

    kitty = {
      font = {
        name = "FiraCode Nerd Font";
        size = 12;
      };
    };

    mpv = {
      enable = true;
      package = pkgs.unstable.mpv;
    };

    neovide = {
      enable = true;
      package = pkgs.unstable.neovide;
      settings = { fork = true; };
    };

    nix-index = { enable = true; };

    ripgrep = { enable = true; };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          setEnv = { TERM = "xterm-256color"; };
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          compression = false;
          addKeysToAgent = "no";
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = null;
        };
      };
      includes = [ "home.conf" ];
    };

    swayimg = { enable = true; };

    swaylock = { enable = true; };

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
      package = pkgs.unstable.yazi;
      shellWrapperName = "y";
    };

    zoxide = { enable = true; };

    nushell = {
      enable = true;
      settings = { show_banner = false; };
      extraConfig = ''
        let carapace_completer = {|spans|
        carapace $spans.0 nushell ...$spans | from json
        }
        # Settings
        $env.config = {
          completions: {
            case_sensitive: false # case-sensitive completions
            quick: false    # set to false to prevent auto-selecting completions
            partial: true    # set to false to prevent partial filling of the prompt
            algorithm: "fuzzy"    # prefix or fuzzy
            external: {
              # set to false to prevent nushell looking into $env.PATH to find more suggestions
              enable: true 
              # set to lower can improve completion performance at the cost of omitting some options
              max_results: 100 
              completer: null # check 'carapace_completer' 
            }
          }
        } 
        $env.config.buffer_editor = "nvim"
        # Environment variables
        $env.EDITOR = "nvim"
        $env.CARAPACE_LENIENT = 1
        $env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense" # optional
        # Aliases
        # Custom commands

        # Opens zellij with a layout, if present.
        #
        # It will look for the layout named, or the default one.
        # If its not found, will open zellij without a custom layout.
        def zz [
          name = "zellij.kdl" # The layout file name
        ] {
          if ($name | path exists) {
            zellij --layout $name
          } else {
            zellij
          }
        }

        #FIXME: This is wrong. Although it works
        mkdir ~/.cache/carapace
        carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
        source ~/.cache/carapace/init.nu
      '';
    };

    carapace = {
      enable = true;
      package = pkgs.unstable.carapace;
    };

    zsh = {
      enable = true;
      autocd = true;
      enableCompletion = true;
      autosuggestion.enable = true;
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
