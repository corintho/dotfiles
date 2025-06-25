{ pkgs, ... }:

{
  imports = [
    ../modules/home/fish.nix
    ../modules/home/ghostty.nix
    ../modules/home/neovim.nix
    ../modules/home/zellij.nix
  ];
  home.stateVersion = "24.11"; # Please read the comment before changing.
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    android-tools
    python3
    # TODO:More nvim
    nixd
    nixfmt-classic
    deadnix
    statix
    # /nvim
  ];

  home.sessionVariables = { EDITOR = "nvim"; };

  # Setup programs options
  programs = {
    bash = { enable = true; };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    git = {
      enable = true;
      userName = "Corintho Assunção";
      userEmail = "zg47ma@insim.biz";
      difftastic = {
        enable = true;
        enableAsDifftool = true;
        display = "inline";
        package = pkgs.unstable.difftastic;
      };
      extraConfig = {
        difftool = { prompt = false; };
        pager = { difftool = true; };
      };
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
    oh-my-posh = { enable = true; };
    ripgrep = { enable = true; };
    zoxide = { enable = true; };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
