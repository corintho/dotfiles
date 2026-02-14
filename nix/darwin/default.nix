{
  self,
  paths,
  inputs,
  nix-darwin,
  nix-homebrew,
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  homebrew-bundle,
  homebrew-cask,
  homebrew-core,
  homebrew-xcodesorg,
  local_flutter_path,
  flutter-local,
  ...
}:

let
  system = "aarch64-darwin";
  username =
    let
      sudoUser = builtins.getEnv "SUDO_USER";
      envUser = builtins.getEnv "USER";
    in
    if sudoUser != "" then
      sudoUser
    else if envUser != "" then
      envUser
    else
      builtins.abort "ERROR: Cannot determine username. Neither SUDO_USER nor USER environment variable is set.";
  rootPath = paths.rootPath;
  nixPath = "${rootPath}/nix";
  files = "${rootPath}/files";
  pkgs = import nixpkgs { inherit system; };
  lcarsConfig = import ../features.nix { inherit pkgs; };
  specialArgs = {
    inherit
      self
      files
      inputs
      nixPath
      username
      rootPath
      paths
      local_flutter_path
      flutter-local
      ;
    libFiles = "${rootPath}/lib";
    lcars = lcarsConfig.lcars;
  };

in
{
  "MPCE-MBP-Y4TJXCG2JX" = nix-darwin.lib.darwinSystem {
    modules = [
      ../options/default.nix
      ../features.nix
      ./jankyborders.nix
      # overlays and modules
      {
        nixpkgs.overlays = [
          (final: _prev: {
            unstable = import nixpkgs-unstable { inherit (final) system config; };
          })
        ];
      }
      inputs.stylix.darwinModules.stylix
      nix-homebrew.darwinModules.nix-homebrew
      home-manager.darwinModules.home-manager

      # The main Darwin configuration, now as a module
      (
        {
          lib,
          pkgs,
          lcars,
          ...
        }:
        {
          system.primaryUser = username;
          environment.systemPackages = with pkgs; [
            comma
            unstable.devenv
            bat
            curl
            neovim
            tmux
            nodejs_22
            (lua5_1.withPackages (ps: with ps; [ luarocks ]))
          ];

          environment.shellAliases = {
            join_img = "convert -background black +smush 16";
            klingon = ''say -v Xander "QgaplA"'';
            listening = "lsof -iTCP -sTCP:LISTEN -n -P";
            n = "nvim";
            gitskipped = "git ls-files -v|grep '^S'";
            gitskip = "git update-index --skip-worktree";
            gitunskip = "git update-index --no-skip-worktree";
            ",," = ", -d ";
          };

          homebrew = {
            enable = true;
            onActivation.cleanup = "zap";
            brews = [
              "mas"
              "xcodes"
              "aria2"
            ];
            casks = [
              "bazecor"
              "copilot-cli"
              "homerow"
              "ghostty"
              "git-credential-manager"
              "raycast"
              "zen"
            ];
            masApps = {
              "Tomito" = 1526042938;
            };
          };

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
              _HIHideMenuBar = false;
              AppleICUForce24HourTime = true;
              AppleInterfaceStyle = "Dark";
              InitialKeyRepeat = 15;
              KeyRepeat = 2;
              NSAutomaticQuoteSubstitutionEnabled = false;
              NSAutomaticWindowAnimationsEnabled = false;
              NSDocumentSaveNewDocumentsToCloud = false;
              NSNavPanelExpandedStateForSaveMode = true;
              NSNavPanelExpandedStateForSaveMode2 = true;
            };
          };

          fonts.packages = with pkgs; [
            nerd-fonts.fira-code
            nerd-fonts.jetbrains-mono
          ];

          security = {
            pki.certificateFiles = [ "/etc/ssl/certs/corporate.crt" ];
            pam.services.sudo_local.touchIdAuth = true;
          };

          # customise /etc/nix/nix.conf declaratively via `nix.settings`
          nix.settings = {
            # enable flakes globally
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            trusted-users = [ "${username}" ];
          };

          programs.fish.enable = lcars.shell.fish.enable;

          system.configurationRevision = if (self ? rev) then self.rev else self.dirtyRev;
          system.stateVersion = 6;
          nixpkgs.hostPlatform = system;
          nixpkgs.config.allowUnfree = true;

          stylix = {
            enable = true;
            polarity = "dark";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
            # base16Scheme = "${files}/lcars.yaml";
            fonts = {
              monospace = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font";
              };
            };
          };

          users = {
            knownUsers = [ username ];
            users.${username} = lib.mkMerge [
              {
                home = "/Users/${username}";
                name = "${username}";
                uid = 501;
              }
              (lib.mkIf lcars.shell.fish.enable {
                shell = lcars.shell.fish.package;
              })
            ];
          };

          nix = {
            enable = true;
            package = pkgs.nix;
            extraOptions = ''
              experimental-features = nix-command flakes
            '';
          };
        }
      )

      # Home-manager user configuration
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import "${nixPath}/darwin/home.nix";
        home-manager.extraSpecialArgs = inputs // specialArgs;
      }
    ];

    specialArgs = specialArgs;
  };
}
