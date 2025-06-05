{ config, lib, dotFiles, pkgs, pkgs-unstable, ... }:

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
    mediainfo
    exiftool
    p7zip
    file-roller
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
    # Custom scripts on path
    (writeShellApplication {
      name = "windows_junctions";
      text = builtins.readFile ./scripts/windows_junctions;
    })
    # /Custom scripts on path
  ];

  xsession = { numlock.enable = true; };

  dconf.settings = {
    "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
    "org/gnome/desktop/peripherals/keyboard" = { numlock-state = true; };
  };

  # Disable modules to handle their style manually
  stylix = { targets = { waybar.enable = false; }; };

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

    rofi = { enable = true; };

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
      package = pkgs-unstable.yazi;
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
        $env.CARAPACE_LENIENT = 1
        $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
        #FIXME: This is wrong. Although it works
        mkdir ~/.cache/carapace
        carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
        source ~/.cache/carapace/init.nu
      '';
    };

    zellij = { enable = true; };

    carapace = {
      enable = true;
      package = pkgs-unstable.carapace;
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
      shellAliases = {
        listening = "lsof -iTCP -sTCP:LISTEN -n -P";
        scripts = ''
          jq ".scripts | to_entries | sort_by(.key) | from_entries" package.json'';
        n = "neovide";
        gitskipped = "git ls-files -v|grep '^S'";
      };
      initContent = lib.mkAfter ''
        # add --skip-worktree flag to file
        gitskip() {  git update-index --skip-worktree "$@";  git status; }
        # remove --skip-worktree flag from file
        gitunskip() {  git update-index --no-skip-worktree "$@";  git status; }
      '';
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
