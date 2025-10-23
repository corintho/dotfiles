{ pkgs, lib, lcars, ... }: {
  config = {
    programs = {
      ghostty = {
        enable = true;
        # For darwin we use the cask
        package =
          (if pkgs.stdenv.isDarwin then null else pkgs.unstable.ghostty);
        settings = {
          font-size = lib.mkForce (if pkgs.stdenv.isDarwin then 14 else 12);
          # Exit without prompt
          confirm-close-surface = false;
          macos-option-as-alt = true;
          command = (if lcars.shell.fish.enable then "fish" else "zsh");
          keybind = [ ] ++ lib.optionals pkgs.stdenv.isDarwin [
            # Fix for MacOS keys
            "alt+left=unbind"
            "alt+right=unbind"
          ];
        };
      };
    };
  };
}
