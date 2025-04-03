{
  description = "Work nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nix-darwin";
    }; 
    # Enable homebrew management through nix
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-xcodesorg = {
      url = "github:xcodesorg/homebrew-made";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager, homebrew-bundle, homebrew-cask, homebrew-core, homebrew-xcodesorg }:
  let
    # nixpkgs.config.allowUnfree = true;
    # Home-manager
    # Reading from environment variables need impure mode, but makes this completely automated for the current user
    username = (builtins.getEnv "USER");
    configuration = { lib, pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
	  # Tools
	  pkgs.bat
	  pkgs.curl
	  pkgs.neovim
	  pkgs.tmux
        ];

      services = {
        nix-daemon = {
	  enable = true;
	};
        aerospace = {
	  enable = false;
	};
        jankyborders = {
	  enable = false;
	};
        sketchybar = {
	  enable = false;
	};
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
	  "ghostty" # The one available from nixpkgs is not official, usually outdated and sometimes broken
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
        (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
      ];

      security = {
        # Setup corporate certficates to be trusted
        pki.certificateFiles = [
          "/etc/ssl/certs/corporate.crt"
        ];
	# Enable touch id for console sudo
	pam.enableSudoTouchIdAuth = true;
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
      # May be needed for some packages. Not for now
      # nixpkgs.config.allowUnfree = true;

      # Home-manager
      users = {
        users.${username} = {
	  # This makes this impure, but makes it fully automated for the current user
	  home = (builtins.getEnv "HOME");
          name = "${username}";
        };
      };
    };
  in
  {
    # Build darwin flake using:
    # darwin-rebuild build --flake .#shield
    darwinConfigurations."shield" = nix-darwin.lib.darwinSystem {
      modules = [ configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            # Enable rosetta on Apple silicon
            enableRosetta = true;
            # Specify homebrew owner
            user = "zg47ma";
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
	home-manager.darwinModules.home-manager {
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.${username} = import ./home.nix;
	}
      ];
    };

    # Exposes the packages list, for convenience
    darwinPackages = self.darwinConfigurations."shield".pkgs;
  };
}
