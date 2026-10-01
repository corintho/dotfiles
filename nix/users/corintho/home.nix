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
    ../../modules/home/steam.nix
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
    # libreoffice
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
  # tensorSplit [ 1 0 ] pins to the 5060, [ 0 1 ] pins to the 2060.
  lcars.models = {
    "unsloth/gemma-4-E4B-it-GGUF:Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--unsloth--gemma-4-E4B-it-GGUF/snapshots/bfc15c382204943c3a8fff0c750b94ae2364d7a3/gemma-4-E4B-it-Q4_K_M.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--unsloth--gemma-4-E4B-it-GGUF/snapshots/bfc15c382204943c3a8fff0c750b94ae2364d7a3/mmproj-BF16.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 128k
      flashAttention = true;
      jinja = true;
      # KoboldCpp-only; llama-server auto-detects SWA from GGUF metadata.
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
      # KoboldCpp-only; llama-server auto-detects SWA from GGUF metadata.
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
      # [ 3 1 ] is the only split that loads at 128k; others OOM. Re-measure after
      # llama.cpp or driver changes.
      tensorSplit = [
        3
        1
      ];
      name = "Qwen3 Coder 30B-A3B UD-Q4_K_XL - 128k (unsloth) (Both)";
      tools = true;
      reasoning = true;
    };
    "empero-ai/Qwen3.8-27B-Ridge-GGUF:Ridge-3.7bpw" = {
      modelPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/Qwen3.8-27B-Ridge-3.7bpw.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/mmproj-Qwen3.8-27B-BF16.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 128k
      # Hybrid (1 in 4 layers full attention) so KV is small, but VRAM headroom is thin:
      # do not raise contextSize. Some compute spills to host, so decode is slower than a clean offload.
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
      contextSize = 131072; # 128k
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      # MTP draft head is in the GGUF; -np 1 is required for it to fit (each extra slot multiplies
      # the recurrent-state buffer by 1 + n-max). Measured faster on code and prose (2026-10-01).
      # Trade-off: one request at a time, one cached conversation.
      extraArgs = [
        "-np"
        "1"
        "--spec-type"
        "draft-mtp"
        "--spec-draft-n-max"
        "2"
      ];
      # [ 5 1 ] gave the fastest decode among the ratios that load cleanly.
      tensorSplit = [
        5
        1
      ];
      name = "Qwen3.8 27B Ridge 3.7bpw - 128k (empero) (Both)";
      reasoning = true;
    };
    "empero-ai/Qwen3.8-27B-Ridge-GGUF:Ridge-3.7bpw-q4max" = {
      modelPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/Qwen3.8-27B-Ridge-3.7bpw.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/mmproj-Qwen3.8-27B-BF16.gguf";
      gpuLayers = -1;
      contextSize = 262144; # native max
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0";
        v = "q4_0";
      };
      # [ 4 1 ] is the only split measured stable at 256k incl. vision input with the default slot
      # count; [ 16 7 ] OOMs on the 2060 at load, [ 5 1 ] crashes on image input, [ 3 1 ] OOMs at depth.
      # `-np 1` would free VRAM on both cards (measured) at the cost of one request at a time.
      # Measured 2026-10-01; re-measure after llama.cpp, driver or display changes.
      tensorSplit = [
        4
        1
      ];
      name = "Qwen3.8 27B Ridge 3.7bpw - 256k (empero) (Both)";
      reasoning = true;
    };
    "empero-ai/Qwen3.8-27B-Ridge-GGUF:Ridge-3.7bpw-64k-mtp" = {
      modelPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/Qwen3.8-27B-Ridge-3.7bpw.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--empero-ai--Qwen3.8-27B-Ridge-GGUF/snapshots/486faa5f2032ff99bdc8993ade1b8fff13d1464c/mmproj-Qwen3.8-27B-BF16.gguf";
      gpuLayers = -1;
      contextSize = 65536;
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0";
        v = "q4_0";
      };
      # Single-card MTP only fits at this context with q4_0 KV and -np 1 (128k OOMs on the MTP
      # compute buffer). Measured faster on code and prose (2026-10-01).
      # Trade-off: one request at a time, one cached conversation.
      extraArgs = [
        "-np"
        "1"
        "--spec-type"
        "draft-mtp"
        "--spec-draft-n-max"
        "2"
      ];
      tensorSplit = [
        1
        0
      ];
      name = "Qwen3.8 27B Ridge 3.7bpw - 64k MTP (empero) (5060)";
      reasoning = true;
    };

    # MiMo-V2.6-Distill-Qwen-9B (bartowski): Qwen3.5-9B dense distill (arch `qwen35`), ChatML +
    # <think>. NOT a MoE despite the HF tags; it only inherits MiMo's chat template.
    # Hybrid GDN: only 1 in 4 layers is full attention, so KV is small and 256k fits on one card.
    # No `useswa`: GDN is not sliding-window.
    # One Q8_0 GGUF serves both keys. The 256k key omits mmproj (its warm-up buffer OOMs at 256k);
    # vision lives on the 128k key. f16 KV does not fit at 256k.
    "bartowski/MiMo-V2.6-Distill-Qwen-9B-GGUF:Q8_0" = {
      modelPath = "${modelsDir}/huggingface/hub/models--bartowski--MiMo-V2.6-Distill-Qwen-9B-GGUF/snapshots/4371da10c84fb26da3592d4cf312d24aa82b7b65/MiMo-V2.6-Distill-Qwen-9B-Q8_0.gguf";
      mmprojPath = "${modelsDir}/huggingface/hub/models--bartowski--MiMo-V2.6-Distill-Qwen-9B-GGUF/snapshots/4371da10c84fb26da3592d4cf312d24aa82b7b65/mmproj-MiMo-V2.6-Distill-Qwen-9B-f16.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 128k, the vision-capable key
      flashAttention = true;
      jinja = true;
      chatTemplateFile = ../../modules/home/chat-templates/mimo-v2.6-distill-qwen-9b.jinja;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      tensorSplit = [
        1
        0
      ];
      name = "MiMo-V2.6 Distill Qwen 9B Q8_0 - 128k + vision (bartowski) (5060)";
      tools = true;
      reasoning = true;
    };
    "bartowski/MiMo-V2.6-Distill-Qwen-9B-GGUF:Q8_0-256k" = {
      modelPath = "${modelsDir}/huggingface/hub/models--bartowski--MiMo-V2.6-Distill-Qwen-9B-GGUF/snapshots/4371da10c84fb26da3592d4cf312d24aa82b7b65/MiMo-V2.6-Distill-Qwen-9B-Q8_0.gguf";
      gpuLayers = -1;
      contextSize = 262144; # 256k native max; text-only, see comment above
      flashAttention = true;
      jinja = true;
      chatTemplateFile = ../../modules/home/chat-templates/mimo-v2.6-distill-qwen-9b.jinja;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0";
        v = "q8_0";
      };
      tensorSplit = [
        1
        0
      ];
      name = "MiMo-V2.6 Distill Qwen 9B Q8_0 - 256k (bartowski) (5060)";
      tools = true;
      reasoning = true;
    };
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
    "huihui/Huihui-Qwen3-8B-abliterated-v2:i1-Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--mradermacher--Huihui-Qwen3-8B-abliterated-v2-i1-GGUF/snapshots/6daf7f7c2a51d6565f78df65e5930ee5f28707e4/Huihui-Qwen3-8B-abliterated-v2.i1-Q4_K_M.gguf";
      gpuLayers = -1;
      contextSize = 49152; # 48k
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q4_0";
        v = "q4_0";
      };
      tensorSplit = [
        0
        1
      ];
      name = "Huihui Qwen3-8B Abliterated v2 (i1 Q4_K_M) - 48k (huihui) (2060)";
      tools = true;
      reasoning = true;
    };
    "huihui/Huihui-Qwen3.5-4B-abliterated:i1-Q4_K_M" = {
      modelPath = "${modelsDir}/huggingface/hub/models--mradermacher--Huihui-Qwen3.5-4B-abliterated-i1-GGUF/snapshots/d9b9a9650c8c52635ab327bb8ceea77bc705e6d7/Huihui-Qwen3.5-4B-abliterated.i1-Q4_K_M.gguf";
      gpuLayers = -1;
      contextSize = 131072; # 128k; 256k OOMs on the 2060
      flashAttention = true;
      jinja = true;
      chatAdapter = "chatml";
      kvQuant = {
        k = "q8_0"; # hybrid: only 1 in 4 layers is full attention
        v = "q8_0";
      };
      tensorSplit = [
        0
        1
      ];
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
      settings."*" = {
        AddKeysToAgent = "no";
        Compression = false;
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ForwardAgent = false;
        HashKnownHosts = false;
        ServerAliveCountMax = 3;
        ServerAliveInterval = 0;
        SetEnv = {
          TERM = "xterm-256color";
        };
        UserKnownHostsFile = "~/.ssh/known_hosts";
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
      initContent = ''
        # Dynamic OPENCODE_API_KEY from the genuine opencode auth store.
        # Runtime-only: nothing is baked into the store at eval time.
        if [[ -z ''${OPENCODE_API_KEY:-} && -r "$HOME/.local/share/opencode/auth.json" ]]; then
          _oc_key="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.local/share/opencode/auth.json")))["opencode"]["key"])' 2>/dev/null)" || true
          [[ -n "$_oc_key" ]] && export OPENCODE_API_KEY="$_oc_key"
          unset _oc_key
        fi
      '';
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
