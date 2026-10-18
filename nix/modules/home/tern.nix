# Tern (https://stencil.so/tern) is a closed-beta binary, and it updates itself:
# "Check for updates" and the `auto_update` preference both replace the file the
# process was started from, then hand the session daemon over to it. A Nix store
# path is immutable, so a store-resident Tern could never take an update --
# "Restart to update" would only re-exec the same store binary. The binary
# therefore lives outside the store, at $HOME/.toolchain/tern/tern-bin, and Nix
# supplies this script instead: the environment for the libraries Tern
# dlopen()s, plus the helper programs it shells out to.
#
# Tern's .desktop entries record the file it is actually running, so they land
# on tern-bin itself -- the launcher cannot be routed through a wrapper, and the
# first launch rewrites anything that pointed elsewhere (observed: all three
# entries flipped to tern-bin the moment current_exe changed). Two mechanisms
# carry that raw path, and neither lives in this script:
#   - programs.nix-ld.libraries (hosts/ncc-1701-d/default.nix) supplies every
#     dlopen()ed library through NIX_LD_LIBRARY_PATH, which the graphical
#     session already inherits;
#   - the helper programs are packages in home.packages, and the session PATH
#     already contains the profile, so zenity and perf resolve from the
#     launcher too.
# What stays here: LD_LIBRARY_PATH, the GIO TLS module, the desktop schemas and
# the gstreamer plugin path for shell launches, and the ~/.local/bin/tern link,
# which the home.file below pins to this script.
#
# The trade: Tern's version stops being a Nix fact. There is no generation
# rollback for it, and a fresh machine re-downloads the tarball once. In
# exchange a version bump needs no redeploy.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Everything Tern dlopen()s, so no RPATH Nix could set would cover it. The
  # binary's DT_NEEDED is only libc/libm/libdl/librt/libpthread/libutil plus
  # libstdc++/libgcc_s, and those two come from programs.nix-ld -- do not shadow
  # them here.
  runtimeLibs = with pkgs; [
    # Browser block.
    webkitgtk_4_1
    # The WPE surface path. nixpkgs has no wpewebkit, so nothing here provides
    # libWPEWebKit-2.0.so.1; if Tern needs it, the browser block is the feature
    # that notices.
    libwpe
    libwpe-fdo
    # wgpu: the Vulkan loader plus the EGL/GLES dispatch that sits in front of
    # the vendor drivers under /run/opengl-driver/lib.
    vulkan-loader
    libglvnd
    # Window input and surface providers.
    libxkbcommon
    libxcb
    wayland
    # libpam: remote login. libpulse-simple: audio inside the browser block.
    linux-pam
    libpulseaudio
    # Screen sharing.
    pipewire
  ];
in
{
  # zenity: Tern's file and confirmation dialogs. glib.bin: the gdbus the
  # settings portal talks to. perf: the perf marks. Packages rather than a PATH
  # prepend in the script because the launcher never runs the script -- what it
  # inherits is the profile, and the session PATH contains it.
  home.packages = [
    pkgs.zenity
    pkgs.glib.bin
    pkgs.perf
    (pkgs.writeShellApplication {
      name = "tern";
      text = ''
        # The binary is not managed by Nix: it replaces itself in place, and it
        # lives beside this script rather than behind it, so a launch that never
        # reaches here still finds a file to exec. $HOME is resolved here rather
        # than at evaluation time, because a build can evaluate with HOME=/root
        # (nixos-rebuild --sudo).
        bin="$HOME/.toolchain/tern/tern-bin"
        if [ ! -x "$bin" ]; then
          echo "tern: no binary at $bin" >&2
          echo "tern: download Tern from https://build.stencil.so/tern and unpack it there" >&2
          echo "tern: tar -xzf Tern-<version>-linux-x86_64.tar.gz -C /tmp && mv /tmp/tern/tern $bin" >&2
          exit 127
        fi

        # Prepend, never replace: the session's LD_LIBRARY_PATH and
        # XDG_DATA_DIRS carry the GPU driver paths and the shell environment
        # Tern's login probe reads.
        export LD_LIBRARY_PATH="${lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

        # WebKitGTK's TLS backend is a GIO module that libsoup dlopens and
        # neither carries; without it the browser block cannot make https
        # requests. The graphical session already exports it, this covers
        # shells that do not.
        export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"

        # Tern reads the org.gnome.desktop.interface schema itself, so the
        # desktop schemas have to be on XDG_DATA_DIRS or the read fails and the
        # settings fall back to Tern's own defaults. Only gnome-shell's own
        # schema directory is on the session's XDG_DATA_DIRS, so this is also
        # the difference between a launcher launch and a shell launch.
        export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"

        # WebKitGTK plays media through gstreamer; without the plugin path it
        # finds no decoder.
        export GST_PLUGIN_SYSTEM_PATH_1_0="${lib.getLib pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0''${GST_PLUGIN_SYSTEM_PATH_1_0:+:$GST_PLUGIN_SYSTEM_PATH_1_0}"

        exec "$bin" "$@"
      '';
    })
  ];

  # The path Tern's ~/.local/bin/tern link points at. Its .desktop entries end
  # up on tern-bin, but this link stays on the path it was created with, so
  # pinning it here keeps it -- and anything else that recorded the path before
  # the rename -- on the script.
  home.file.".toolchain/tern/tern".source = "${config.home.path}/bin/tern";
}
