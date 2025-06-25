{ pkgs, lib, ... }: {
  config = {
    programs = {
      ghostty = {
        enable = true;
        #TODO: Unify installation
        # For darwin we use the cask
        package =
          (if pkgs.stdenv.isDarwin then null else pkgs.unstable.ghostty);
        settings = {
          macos-option-as-alt = true;
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
