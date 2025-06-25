{ self, paths, inputs, nix-darwin, nix-homebrew, nixpkgs-unstable, home-manager
, homebrew-bundle, homebrew-cask, homebrew-core, homebrew-xcodesorg, ... }:
let
  rootPath = paths.rootPath;
  nixPath = "${rootPath}/nix";
  files = "${rootPath}/files";
  # Passes these parameters to other nix modules
  specialArgs = {
    inherit self files inputs nixPath username rootPath paths;
    libFiles = "${rootPath}/lib";
  };
  # nixpkgs.config.allowUnfree = true;
  # Home-manager
  username = "zg47ma";
  configuration = { pkgs, ... }: {
    # Setup primary user. We need to eventually remove this and migrate configurations properly
    system.primaryUser = username;
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [
      comma
      # Coding tools
      devenv
      # /Coding tools
      # Tools
      bat
      curl
      neovim
      tmux
      # Requirements for nvim
      nodejs_22
      (lua5_1.withPackages (ps: with ps; [ luarocks ]))
      # /nvim
    ];

    environment.shellAliases = {
      bad_watchman =
        "watchman watch-del '$PWD' ; watchman watch-project '$PWD'";
      check = "yarn lint && yarn typescript && yarn test";
      ios = "xcrun simctl getenv booted SIMULATOR_UDID | xargs yarn ios --udid";
      ios_device =
        ''ios-deploy -c | grep USB | cut -d " " -f 3 | xargs yarn ios --udid'';
      join_img = "convert -background black +smush 16";
      klingon = ''say -v Xander "QgaplA"'';
      listening = "lsof -iTCP -sTCP:LISTEN -n -P";
      scripts = ''
        jq ".scripts | to_entries | sort_by(.key) | from_entries" package.json'';
      n = "nvim";
      gitskipped = "git ls-files -v|grep '^S'";
      gitskip = "git update-index --skip-worktree";
      gitunskip = "git update-index --no-skip-worktree";
    };

    services = {
      aerospace = { enable = false; };
      jankyborders = { enable = false; };
      sketchybar = { enable = false; };
    };

    homebrew = {
      enable = true;
      # Remove extraneous brew packages that managed to get in place somehow
      onActivation.cleanup = "zap";
      brews = [
        "mas" # Required to install store applications
        # Tool to handle xcode installation: https://github.com/XcodesOrg/xcodes
        "xcodes"
        # Allows parallelized downloads
        "aria2"
      ];
      casks = [
        "homerow"
        "ghostty" # The one available from nixpkgs is marked as broken
        "git-credential-manager" # The one from nixpkgs showed issues with finding .NET
        "tomatobar"
      ];
      masApps = {
        # Don't install XCode from the store, install using xcodes
        #"Xcode" = 497799835;
      };
    };

    # OSX Configuration - More information: https://mynixos.com/nix-darwin/options/system.defaults
    system.defaults = {
      controlcenter.BatteryShowPercentage = true;
      dock.autohide = true;
      finder = {
        _FXSortFoldersFirst = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      loginwindow.GuestEnabled = false;
      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.swipescrolldirection" = false;
        _HIHideMenuBar = false; # Change to true after setting up sketchybar
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        # Fastest possible values from OSX UI. Needs to re-login to take effect
        InitialKeyRepeat = 15; # Can be 10, although not in the UI
        KeyRepeat = 2; # Can be 1, although not in the UI as well
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
      };
    };

    # Fonts
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];

    security = {
      # Setup corporate certficates to be trusted
      pki.certificateFiles = [ "/etc/ssl/certs/corporate.crt" ];
      # Enable touch id for console sudo
      pam.services.sudo_local.touchIdAuth = true;
    };

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Enable alternative shell support in nix-darwin.
    programs.fish.enable = true;

    # Set Git commit hash for darwin-version.
    system.configurationRevision =
      if (self ? rev) then self.rev else self.dirtyRev;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 6;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = "aarch64-darwin";
    # May be needed for some packages. Not for now
    # nixpkgs.config.allowUnfree = true;

    # Enable system wide styling
    stylix = {
      enable = true;
      polarity = "dark";
      base16Scheme = "${files}/lcars.yaml";
      # image = ../../../wallpapers/973571.jpg;
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
      };
    };
    # Home-manager
    users = {
      knownUsers = [ username ];
      users.${username} = {
        home = "/Users/${username}";
        name = "${username}";
        uid = 501;
        shell = pkgs.fish;
      };
    };

    nix = {
      enable = true;
      package = pkgs.nix;
      extraOptions = ''
        # auto-optimise-store = true
        experimental-features = nix-command flakes
      '';
    };
  };
in {
  inherit specialArgs;
  # Build darwin flake using:
  "MPCE-MBP-Y4TJXCG2JX" = nix-darwin.lib.darwinSystem {
    modules = [
      {
        nixpkgs.overlays = [
          (final: _prev: {
            unstable =
              import nixpkgs-unstable { inherit (final) system config; };
          })
          (_final: prev: {
            zjstatus = inputs.zjstatus.packages.${prev.system}.default;
          })
        ];
      }
      inputs.stylix.darwinModules.stylix
      configuration
      nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          enable = true;
          # Enable rosetta on Apple silicon
          enableRosetta = true;
          # Specify homebrew owner
          user = username;
          # Disable manual brew installation
          mutableTaps = false;
          # Programatically enable taps
          taps = {
            "homebrew/homebrew-bundle" = homebrew-bundle;
            "homebrew/homebrew-cask" = homebrew-cask;
            "homebrew/homebrew-core" = homebrew-core;
            "homebrew/homebrew-xcodesorg" = homebrew-xcodesorg;
          };
        };
      }
      home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import "${nixPath}/darwin/home.nix";
        # Optionally, use home-manager.extraSpecialArgs to pass
        # arguments to home.nix
        # Sets home manager to use the same special args as flakes
        home-manager.extraSpecialArgs = inputs // specialArgs;
      }
    ];
  };

  # Exposes the packages list, for convenience
  darwinPackages = self.darwinConfigurations."shield".pkgs;
}
