{ lcars, lib, pkgs, ... }:

let fishModule = ../modules/home/fish.nix;
in {
  imports = [
    ../modules/home/ghostty.nix
    # ../modules/home/gitui.nix
    ../modules/home/helix.nix
    ../modules/home/neovim.nix
    ../modules/home/oh_my_posh.nix
    ../../modules/home/zed.nix
    ../modules/home/zellij.nix
    ../modules/home/darwin
  ] ++ (lib.optional lcars.shell.fish.enable fishModule);
  home.stateVersion = "24.11"; # Please read the comment before changing.
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    android-tools
    python3
    fd
    tldr
    # TODO:More nvim
    nixd
    nixfmt-classic
    deadnix
    statix
    wget
    imagemagickBig
    # /nvim
    unstable.kitty
    unstable.obsidian
    unstable.lazygit
  ];

  home.sessionVariables = { EDITOR = "hx"; };

  # Setup programs options
  programs = {
    bash = { enable = true; };
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
      settings = {
        user = {
          name = "Corintho Assunção";
          email = "zg47ma@insim.biz";
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
    fzf = { enable = true; };
    ripgrep = { enable = true; };
    zoxide = { enable = true; };
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
