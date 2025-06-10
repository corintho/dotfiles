{ self, pkgs, lib, username, ... }: {
  system.configurationRevision =
    if (self ? rev) then self.rev else self.dirtyRev;
  # ============================= User related =============================

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # customise /etc/nix/nix.conf declaratively via `nix.settings`
  nix.settings = {
    # enable flakes globally
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "${username}" ];
  };
  nix.channel.enable = false;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    comma
    curl
    just
    kitty
    nix-index
    wget
    nix-tree
  ];

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
      LC_CTYPE = "pt_BR.UTF-8"; # Fix to use ç instead of ć
    };
  };

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      package = pkgs.unstable.neovim-unwrapped;
    };

    git = {
      enable = true;
      lfs.enable = true;
      config = { init = { defaultBranch = "main"; }; };
    };
    # Install zsh
    zsh.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  fonts = {
    packages = with pkgs; [
      # icon fonts
      #material-design-icons

      # normal fonts
      #noto-fonts
      #noto-fonts-cjk
      #noto-fonts-emoji

      # nerdfonts
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];

    # use fonts specified by user rather than default ones
    #enableDefaultPackages = false;

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    #fontconfig.defaultFonts = {
    #serif = ["Noto Serif" "Noto Color Emoji"];
    #sansSerif = ["Noto Sans" "Noto Color Emoji"];
    #monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
    #emoji = ["Noto Color Emoji"];
    #};
  };
}
