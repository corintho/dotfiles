{ pkgs, ... }:

{
  # Counterpart of zen-export (NixOS): installs the exported .xpi files into a Zen profile.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "zen-import";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gawk
        pkgs.jq
        pkgs.lsof
        pkgs.unzip
      ];
      text = builtins.readFile ../zen-offline-sync/zen-import.sh;
    })
  ];
}
