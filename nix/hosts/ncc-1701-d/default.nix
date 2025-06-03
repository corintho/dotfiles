{ dotFiles, inputs, lib, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ../../modules/system.nix
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 5; # the default is 5

    # For additional reference: https://wiki.nixos.org/wiki/Dual_Booting_NixOS_and_Windows#systemd-boot_2
    systemd-boot = {
      enable = true;

      # There is no way to change the default boot option from configuration. But it can be done through command line with: `bootctl set-default windows_windows.conf`. Not sure how to undo it in the future
      windows = {
        "windows" = let boot-drive = "HD1c";
        in {
          title = "Windows";
          efiDeviceHandle = boot-drive;
          # Adding a sort key beginning with a letter earlier than "n", puts it in front of "nixos"
          sortKey = "a_windows";
        };
      };

      edk2-uefi-shell.enable = true;
      edk2-uefi-shell.sortKey = "z_edk2";
    };
  };

  networking.hostName = "ncc-1701-d"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable Hyprland
  services.xserver.displayManager.gdm.wayland = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable dconf to setup options
  programs.dconf = {
    enable = true;
    # Enable numlock for GUI
    profiles = {
      gdm.databases = [{
        settings = {
          "org/gnome/desktop/peripherals/keyboard" = {
            numlock-state = true;
            remember-numlock-state = true;
          };
        };
      }];
    };
  };

  # Enable numlock for ttys
  systemd.services.numLockOnTty = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      # /run/current-system/sw/bin/setleds -D +num < "$tty";
      ExecStart = lib.mkForce (pkgs.writeShellScript "numLockOnTty" ''
        for tty in /dev/tty{1..6}; do
            ${pkgs.kbd}/bin/setleds -D +num < "$tty";
        done
      '');
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Enable system wide styling
  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${dotFiles}/lcars.yaml";
    image = ../../../wallpapers/973571.jpg;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
    coreutils-full
    # Requirements for nvim
    gcc
    gnumake
    nodejs_22
    unzip
    wl-clipboard-rs
    (lua5_1.withPackages (ps: with ps; [ luarocks ]))
    # /nvim
    kitty
    rofi
    inputs.zen-browser.packages.${pkgs.system}.default
    hyprpicker
    cifs-utils
    samba
  ];

  # Workaround to enable binaries downloaded outside nix to work
  # Includes nvim mason dependencies and app-image applications
  programs.nix-ld = {
    enable = true;
    package = pkgs-unstable.nix-ld;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
