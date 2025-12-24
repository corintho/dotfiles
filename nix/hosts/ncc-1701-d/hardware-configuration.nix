{ config, lib, modulesPath, ... }:
let ntfsOptions = [ "rw" "uid=1000" "allow_other" "default_permissions" ];
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Enable NTFS support on boot
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/38259b95-00cb-4d09-bd52-f5c62a1de312";
    fsType = "ext4";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/23b68d6b-4e1b-4d28-a3a3-5a52b14834e9";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8572-4959";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/4c55dccc-a012-419a-8e7e-1eea368233eb"; }];

  # Windows shares
  fileSystems."/windows/c" = {
    device = "/dev/disk/by-uuid/289ABCE09ABCAC26";
    fsType = "ntfs-3g";
    options = ntfsOptions;
  };

  fileSystems."/windows/d" = {
    device = "/dev/disk/by-uuid/9410022310020D44";
    fsType = "ntfs-3g";
    options = ntfsOptions;
  };

  fileSystems."/windows/e" = {
    device = "/dev/disk/by-uuid/AE26A28A26A2535F";
    fsType = "ntfs-3g";
    options = ntfsOptions;
  };

  fileSystems."/windows/f" = {
    device = "/dev/disk/by-uuid/3C240C2C240BE7AA";
    fsType = "ntfs-3g";
    options = ntfsOptions;
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable power button to shutdown
  services.logind = {
    # Disable idle action, since we handle it differently already
    settings = {
      Login = {
        HandlePowerKey = "ignore";
        HandlePowerKeyLongPress = "poweroff";
        IdleAction = "ignore";
      };
    };
  };

  # Load nvidia drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Bluetooth pairing services
  services.blueman.enable = true;

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable QMK patching
  hardware.keyboard.qmk.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
