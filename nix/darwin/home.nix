{
  lcars,
  lib,
  pkgs,
  username,
  local_flutter_path,
  flutter-local,
  ...
}:

let
  fishModule = ../modules/home/fish.nix;
in
{
  imports = [
    ../modules/home/ghostty.nix
    ../modules/home/gitui.nix
    ../modules/home/helix.nix
    ../modules/home/neovim.nix
    ../modules/home/oh_my_posh.nix
    ../modules/home/opencode.nix
    ../modules/home/models.nix
    # ../modules/home/zed.nix
    ../modules/home/zellij.nix
    ../modules/home/darwin
  ]
  ++ (lib.optional lcars.shell.fish.enable fishModule);
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # Disable stylix GTK theming on macOS (not needed/used)
  stylix.targets.gtk.enable = false;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    android-tools
    python3
    fd
    tldr
    # TODO:More nvim
    nixd
    nixfmt
    deadnix
    statix
    wget
    imagemagickBig
    # /nvim
    unstable.kitty
    unstable.obsidian
    unstable.lazygit
    (pkgs.tesseract.override {
      enableLanguages = [
        "eng"
        "nld"
        "por"
      ];
    })
    markpad
    # Custom scripts
    (writeShellApplication {
      name = "local-route-fix";
      text = ''
        sudo bash -c '
          set -e
          route delete -net 192.168.2.0/24 2>/dev/null || true
          route add -net 192.168.2.0/24 192.168.2.254
        '
      '';
    })
    (writeShellApplication {
      name = "network-always-on";
      text = ''
        sudo pmset -a networkoversleep 1
      '';
    })
  ];

  # Local llama.cpp models (drives llama-swap + opencode)
  lcars.models = {
    "ggml-org/gemma-4-E4B-it-GGUF:Q8_0" = {
      modelPath = "/Users/${username}/.cache/huggingface/hub/models--ggml-org--gemma-4-E4B-it-GGUF/snapshots/6d556b1304a00d2a95a62f567bb2df5ff5abb936/gemma-4-E4B-it-Q8_0.gguf";
      mmprojPath = "/Users/${username}/.cache/huggingface/hub/models--ggml-org--gemma-4-E4B-it-GGUF/snapshots/6d556b1304a00d2a95a62f567bb2df5ff5abb936/mmproj-gemma-4-E4B-it-Q8_0.gguf";
      name = "Gemma 4 E4B IT Q8";
    };
    "unsloth/Qwen3-14B-GGUF:UD-Q4_K_XL" = {
      modelPath = "/Users/${username}/.cache/huggingface/hub/models--unsloth--Qwen3-14B-GGUF/snapshots/a04a82c4739b3ef5fa6da7d10261db2c67dd1985/Qwen3-14B-UD-Q4_K_XL.gguf";
      extraArgs = [ "--jinja" "-fa" "on" ];
      name = "Qwen3 14B UD Q4_K_XL";
      reasoning = true;
    };
    "unsloth/Qwen2.5-Coder-14B-Instruct-GGUF:Q4_K_M" = {
      modelPath = "/Users/${username}/.cache/huggingface/hub/models--unsloth--Qwen2.5-Coder-14B-Instruct-GGUF/snapshots/388f3f20271ef903bb2dbe7d8236158903e7edb3/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf";
      extraArgs = [ "--jinja" "-fa" "on" ];
      name = "Qwen2.5 Coder 14B Q4_K_M";
    };
  };

  home.sessionVariables = {
    EDITOR = "hx";
    PATH = "${local_flutter_path}/flutter/bin:$PATH";
  };

  home.activation = {
    installFlutter = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${local_flutter_path}
      # installs flutter locally, if not there already
      run "${flutter-local.unpack_flutter}/bin/unpack_flutter"
    '';
  };
  # Setup programs options
  programs = {
    bash = {
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
    git = {
      enable = true;
      lfs.enable = true;
      includes = [
        { path = "~/.config/git/local"; }
      ];
      settings = {
        init = {
          defaultBranch = "main";
        };
        user = {
          name = "Corintho Assunção";
        };
        difftool = {
          prompt = false;
        };
        pager = {
          difftool = true;
        };
      };
      signing.format = null;
    };

    man.generateCaches = false;

    opencode = {
      settings = {
        model = "github-copilot/claude-sonnet-4.6";
        agent = {
          plan.model = "github-copilot/claude-sonnet-4.6";
          build.model = "github-copilot/claude-haiku-4.5";
        };
      };
    };
    zed-editor = {
      enable = true;
      package = pkgs.unstable.zed-editor;
    };

    difftastic = {
      enable = true;
      options = {
        enableAsDifftool = true;
        display = "inline";
      };
      package = pkgs.unstable.difftastic;
    };
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
    };
    fzf = {
      enable = true;
    };
    ripgrep = {
      enable = true;
    };
    zoxide = {
      enable = true;
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
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
