{ config, pkgs, ... }:

{
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

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # Dirty, impure, but creates the direct link we want for some things. It needs to be a absolute path to work. If it is relative, it creates a file in the store with the contents of the linked file
    ".config/ghostty/" = {
      source = config.lib.file.mkOutOfStoreSymlink ../. + "/config/ghostty/";
      # In order to do folders, we need to do it recursive
      recursive = true;
    };
  };

  # Link files into XDG dirs
  # xdg.configFile = {};

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/zg47ma/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = { EDITOR = "nvim"; };

  # Setup programs options
  programs = {
    bash = { enable = true; };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
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
      shellAliases = {
        bad_watchman =
          "watchman watch-del '$PWD' ; watchman watch-project '$PWD'";
        check = "yarn lint && yarn typescript && yarn test";
        ios =
          "xcrun simctl getenv booted SIMULATOR_UDID | xargs yarn ios --udid";
        ios_device = ''
          ios-deploy -c | grep USB | cut -d " " -f 3 | xargs yarn ios --udid'';
        join_img = "convert -background black +smush 16";
        klingon = ''say -v Xander "QgaplA"'';
        listening = "lsof -iTCP -sTCP:LISTEN -n -P";
        scripts = ''
          jq ".scripts | to_entries | sort_by(.key) | from_entries" package.json'';
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
