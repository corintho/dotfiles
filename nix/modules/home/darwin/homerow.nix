{ lib, ... }:

let
  homerowSettings = {
    label-characters = "NEIOTSRA";
    enable-hyper-key = false;
    non-search-shortcut = "⌥Z";
    auto-switch-input-source-id = "com.apple.keylayout.ABC";
    map-arrow-keys-to-scroll = true;
    use-search-predicate = true;
    launch-at-login = true;
    scroll-keys = "";
    scroll-shortcut = "⌥X";
  };

  boolToDefaults = value: if value then "-bool true" else "-bool false";

  defaultsCommands = lib.concatStringsSep "\n    " (lib.mapAttrsToList
    (key: value:
      let
        valueArg = if lib.isBool value then
          boolToDefaults value
        else
          ''"${toString value}"'';
      in "run /usr/bin/defaults write com.superultra.Homerow ${key} ${valueArg}")
    homerowSettings);

in {
  home.activation.configureHomerow =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Configuring Homerow preferences..."
      ${defaultsCommands}
    '';
}
