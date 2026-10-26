{
  config,
  files,
  pkgs,
  ...
}:

{
  # Extension list read by zen-export; editable in-repo without a rebuild.
  xdg.configFile."zen-offline-sync/zen-export-config.yaml".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/zen-offline-sync/zen-export-config.yaml";

  # Copies the listed Zen .xpi extensions to the SMB share for offline install.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "zen-export";
      runtimeInputs = [
        pkgs.coreutils
      ];
      text = builtins.readFile ./zen-offline-sync/zen-export.sh;
    })
  ];
}
