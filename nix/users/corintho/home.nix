{
  config,
  files,
  lcars,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  modelsDir = "/windows/c/ai/llama";
  fishModule = ../../modules/home/fish.nix;
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.omp.homeManagerModules.default
    ../../home/core.nix
    ../../modules/home/user_secrets.nix
    ../../modules/home/ghostty.nix
    ../../modules/home/gdu.nix
    ../../modules/home/gitui.nix
    ../../modules/home/helix.nix
    ../../modules/home/herdr.nix
    ../../modules/home/hyprland.nix
    ../../modules/home/hyprpaper.nix
    ../../modules/home/niri.nix
    ../../modules/home/neovim.nix
    ../../modules/home/emacs.nix
    ../../modules/home/oh_my_posh.nix
    ../../modules/home/opencode.nix
    ../../modules/home/oh_my_pi.nix
    # ../../modules/home/qtile.nix
    ../../modules/home/rofi.nix
    ../../modules/home/waybar.nix
    ../../modules/home/nixos
    ../../modules/home/models.nix
    ../../modules/home/zed.nix
    ../../modules/home/zellij.nix
  ]
  ++ (lib.optional lcars.shell.fish.enable fishModule);
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
    unstable.nvitop
    # Gaming
    prismlauncher
    unstable.discord
    # 3D printing
    (pkgs.symlinkJoin {
      name = "orca-slicer";
      paths = [ pkgs.orca-slicer ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/orca-slicer --set GTK_THEME Adwaita:dark
      '';
    })
    # AI
    unstable.alpaca
    unstable.ollama
    unstable.handy
    google-chrome
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
    (pkgs.tesseract.override {
      enableLanguages = [
        "eng"
        "nld"
        "por"
      ];
    })
    # /Screen capturing
    # Freecad
    freecad
    # /Freecad
    unstable.obsidian
    # Sweet home 3d
    unstable.sweethome3d.application
    unstable.sweethome3d.textures-editor
    unstable.sweethome3d.furniture-editor
    (writeShellApplication {
      name = "sweethome3d-fixed";
      text = ''JAVA_TOOL_OPTIONS="-Dcom.eteks.sweethome3d.j3d.useOffScreen3DView=true" ${unstable.sweethome3d.application}/bin/sweethome3d "$@"'';
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
    (import ../../modules/home/herdr-package.nix {
      inherit inputs pkgs;
      system = pkgs.stdenv.hostPlatform.system;
    })
  ];

  # Workaround: `handy` (cjpais/Handy speech-to-text) bundles its own ggml
  # runtime (libggml-*.so), and so does `llama-cpp`. Both land in home.packages,
  # so buildEnv refuses to merge the profile on the conflicting subpath
  # `/lib/libggml-base.so`. Force the profile buildEnv to tolerate the collision:
  # each program resolves its own ggml copy via its store-path RPATH, so the
  # single shadowed copy in the merged profile is never actually loaded.
  home.path = lib.mkForce (
    pkgs.buildEnv {
      name = "home-manager-path";
      paths = config.home.packages;
      inherit (config.home) extraOutputsToInstall;
      postBuild = config.home.extraProfileCommands;
      ignoreCollisions = true;
      meta = {
        description = "Environment of packages installed through home-manager";
      };
    }
  );

  # Local inference models (engine-agnostic: drives llama-swap, koboldcpp, opencode)
  lcars.models = {
    "unsloth/gemma-4-E4B-it-GGUF:Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--unsloth--gemma-4-E4B-it-GGUF/snapshots/bfc15c382204943c3a8fff0c750b94ae2364d7a3/gemma-4-E4B-it-Q4_K_M.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--unsloth--gemma-4-E4B-it-GGUF/snapshots/bfc15c382204943c3a8fff0c750b94ae2364d7a3/mmproj-BF16.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 128k
      flashAttention = true;
      jinja = true;
      useswa = true;
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      tensorSplit = [
        1
        0
      ];
      name = "Gemma 4 E4B IT Q4_K_M - 128k (unsloth) (5060)";
    };
    "unsloth/gemma-4-E4B-it-GGUF:Q4_K_M-2060" = {
      modelPath = "${modelsDir}/huggingface/hub/models--unsloth--gemma-4-E4B-it-GGUF/snapshots/bfc15c382204943c3a8fff0c750b94ae2364d7a3/gemma-4-E4B-it-Q4_K_M.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--unsloth--gemma-4-E4B-it-GGUF/snapshots/bfc15c382204943c3a8fff0c750b94ae2364d7a3/mmproj-BF16.gguf";
      gpuLayers = -1;
      contextSize = 24576; # 24k
      flashAttention = true;
      jinja = true;
      useswa = true;
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      tensorSplit = [
        0
        1
      ];
      name = "Gemma 4 E4B IT Q4_K_M - 24k (unsloth) (2060)";
    };
    "unsloth/Qwen3-14B-GGUF:UD-Q4_K_XL" = {
      modelPath = "${modelsDir}/huggingface/hub/models--unsloth--Qwen3-14B-GGUF/snapshots/a04a82c4739b3ef5fa6da7d10261db2c67dd1985/Qwen3-14B-UD-Q4_K_XL.gguf";
      gpuLayers = 20;
      contextSize = 16384;
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      name = "Qwen3 14B UD Q4_K_XL - 16k (unsloth) (Both)";
      reasoning = true;
    };
    "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL" = {
      modelPath = "${modelsDir}/huggingface/hub/models--unsloth--Qwen3-Coder-30B-A3B-Instruct-GGUF/snapshots/b17cb02dd882d5b6ab62fc777ad2995f19668350/Qwen3-Coder-30B-A3B-Instruct-UD-Q4_K_XL.gguf";
      gpuLayers = -1;
      contextSize = 131072;
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0";
        v = "q4_0";
      };
      tensorSplit = [
        2
        1
      ];
      name = "Qwen3 Coder 30B-A3B UD-Q4_K_XL - 128k (unsloth) (Both)";
      tools = true;
      reasoning = true;
    };
    "unsloth/Qwen3.8-27B-GGUF:UD-Q3_K_XL" = {
      modelPath = "${modelsDir}/huggingface/hub/models--unsloth--Qwen3.8-27B-GGUF/Qwen3.8-27B-UD-Q3_K_XL.gguf";
      gpuLayers = -1;
      contextSize = 131072;
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      tensorSplit = [
        2
        1
      ];
      name = "Qwen3.8 27B UD Q3_K_XL - 128k (unsloth) (Both)";
    };
    "williamliao/Qwen3.8-27B-NVFP4-GGUF:NVFP4-Quality-v2" = {
      modelPath = "${modelsDir}/huggingface/hub/models--williamliao--Qwen3.8-27B-NVFP4-GGUF/Qwen3.8-27B-NVFP4-Quality-v2.gguf";
      gpuLayers = -1;
      contextSize = 24576;
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0";
        v = "q4_0";
      };
      tensorSplit = [
        1
        0
      ];
      name = "Qwen3.8 27B NVFP4 Quality-v2 - 24k (williamliao) (5060)";
    };
    "empero-ai/Qwen3.8-27B-Ridge-GGUF:Ridge-3.7bpw" = {
      modelPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/Qwen3.8-27B-Ridge-3.7bpw.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/mmproj-Qwen3.8-27B-BF16.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 128k — 5060 Ti (16 GB): 16 - 11.73 weights - 0.87 mmproj - 0.3 CUDA ≈ 3.1 GiB for KV; Q4_0 empirical ~28 KB/token × 128k ≈ 3.5 GiB
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0";
        v = "q4_0";
      };
      tensorSplit = [
        1
        0
      ];
      name = "Qwen3.8 27B Ridge 3.7bpw - 128k (empero) (5060)";
      reasoning = true;
    };
    "empero-ai/Qwen3.8-27B-Ridge-GGUF:Ridge-3.7bpw-2gpu" = {
      modelPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/Qwen3.8-27B-Ridge-3.7bpw.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/mmproj-Qwen3.8-27B-BF16.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 128k — Q8_0 fits both GPUs, verified: Q3_K_XL (12.52 GiB, heavier) runs Q8_0@128k with 707 MiB headroom on 2060 SUPER; Ridge is ~0.8 GiB lighter
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      tensorSplit = [
        2
        1
      ];
      name = "Qwen3.8 27B Ridge 3.7bpw - 128k (empero) (Both)";
      reasoning = true;
    };
    "empero-ai/Qwen3.8-27B-Ridge-GGUF:Ridge-3.7bpw-q4max" = {
      modelPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/Qwen3.8-27B-Ridge-3.7bpw.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/mmproj-Qwen3.8-27B-BF16.gguf";
      gpuLayers = -1;
      contextSize = 262144; # 256k native max — Q4_0 halves per-token KV vs Q8_0; smoke-test to find true limit
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0";
        v = "q4_0";
      };
      tensorSplit = [
        2
        1
      ];
      name = "Qwen3.8 27B Ridge 3.7bpw - 256k (empero) (Both)";
      reasoning = true;
    };

    # Vision / OCR / GUI (Qwen3-VL, ChatML)
    "Qwen/Qwen3-VL-8B-Instruct:Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--bartowski--Qwen_Qwen3-VL-8B-Instruct-GGUF/snapshots/6398fcccbd940691854d2cffd85b435ed8eee4ca/Qwen_Qwen3-VL-8B-Instruct-Q4_K_M.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--bartowski--Qwen_Qwen3-VL-8B-Instruct-GGUF/snapshots/6398fcccbd940691854d2cffd85b435ed8eee4ca/mmproj-Qwen_Qwen3-VL-8B-Instruct-bf16.gguf";
      gpuLayers = -1;
      contextSize = 32768;
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      name = "Qwen3-VL 8B Instruct Q4_K_M - 32k (Qwen) (Both)";
    };

    # Coding (Qwen2.5-Coder-14B, ChatML) — added alongside the 30B-MoE coder
    "Qwen/Qwen2.5-Coder-14B:Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--bartowski--Qwen2.5-Coder-14B-GGUF/snapshots/0e179a81290a5e9b04bb1b4f1badf79bc880b261/Qwen2.5-Coder-14B-Q4_K_M.gguf";
      gpuLayers = -1;
      contextSize = 32768;
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      name = "Qwen2.5 Coder 14B Q4_K_M - 32k (Qwen) (Both)";
    };

    # Roleplay / creative writing (Llama-based -> native jinja, no chatAdapter)
    "bartowski/writing-roleplay-20k-context-nemo-12b-v1.0:Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--bartowski--writing-roleplay-20k-context-nemo-12b-v1.0-GGUF/snapshots/cecefa746b717ffb42ec31c42fb4faf977cf6ca2/writing-roleplay-20k-context-nemo-12b-v1.0-Q4_K_M.gguf";
      gpuLayers = -1;
      contextSize = 24576;
      flashAttention = true;
      jinja = true;
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      name = "Writing-Roleplay Nemo 12B v1.0 Q4_K_M - 24k (bartowski) (Both)";
    };

    # huihui abliterated ("uncensored") — pinned to GPU1 (2060, 8 GB), tensorSplit [ 0 1 ]
    "huihui/Huihui-Qwen3-8B-abliterated-v2:i1-Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--mradermacher--Huihui-Qwen3-8B-abliterated-v2-i1-GGUF/snapshots/6daf7f7c2a51d6565f78df65e5930ee5f28707e4/Huihui-Qwen3-8B-abliterated-v2.i1-Q4_K_M.gguf";
      gpuLayers = -1;
      contextSize = 49152; # 48k
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0"; # fp16 KV @48k = ~6.9 GB -> q4_0 = ~1.8 GB; fits
        v = "q4_0";
      };
      tensorSplit = [
        0
        1
      ]; # pin to GPU1 (2060)
      name = "Huihui Qwen3-8B Abliterated v2 (i1 Q4_K_M) - 48k (huihui) (2060)";
      tools = true;
      reasoning = true;
    };
    "huihui/Huihui-Qwen3.5-4B-abliterated:i1-Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--mradermacher--Huihui-Qwen3.5-4B-abliterated-i1-GGUF/snapshots/d9b9a9650c8c52635ab327bb8ceea77bc705e6d7/Huihui-Qwen3.5-4B-abliterated.i1-Q4_K_M.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 256k OOM'd on GPU1 (8 GB); 131072 is largest that loads
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0"; # hybrid: only 8 full-attn layers; q8 KV @256k ~4 GB
        v = "q8_0";
      };
      tensorSplit = [
        0
        1
      ]; # pin to GPU1 (2060)
      name = "Huihui Qwen3.5-4B Abliterated (i1 Q4_K_M) - 128k (huihui) (2060)";
      tools = true;
      reasoning = true;
    };
  };

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

  home.sessionVariables = {
    EDITOR = "hx";
    OLLAMA_MODELS = "/windows/e/__Slow_AI_E/ollama";
    LLAMA_CPP_BASE_URL = "http://127.0.0.1:1234/v1";
    HF_HOME = "${modelsDir}/huggingface";
    PI_CONFIG_FILES = "${files}/omp/omp_nixos_config.yml";
  };
  xsession = {
    numlock.enable = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };
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
    bat = {
      enable = true;
    };

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

    fzf = {
      enable = true;
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "Corintho Assunção";
          email = "github@corintho.eu";
        };
        difftool = {
          prompt = false;
        };
        pager = {
          difftool = true;
        };
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
      settings = {
        fork = true;
      };
    };

    nix-index = {
      enable = true;
    };

    ripgrep = {
      enable = true;
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          setEnv = {
            TERM = "xterm-256color";
          };
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

    swayimg = {
      enable = true;
    };

    swaylock = {
      enable = true;
    };

    vicinae = {
      enable = true;
      settings = {
        "favorites" = [
          "applications:emacsclient"
          "applications:obsidian"
          "applications:net.lutris.Lutris"
          "applications:org.prismlauncher.PrismLauncher"
        ];
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
      package = pkgs.unstable.yazi;
      shellWrapperName = "y";
    };

    zoxide = {
      enable = true;
    };

    nushell = {
      enable = true;
      settings = {
        show_banner = false;
      };
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
      events = {
        before-sleep = "${pkgs.swaylock}/bin/swaylock -fF";
        lock = "lock";
      };
      timeouts = [
        {
          timeout = 290;
          command = "${pkgs.libnotify}/bin/notify-send 'Locking in 10 seconds' -t 10000";
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

    swaync = {
      enable = true;
    };
  };
}
