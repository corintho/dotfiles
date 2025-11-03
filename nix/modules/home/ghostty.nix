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
          font-family = "FiraCode Nerd Font";
          # Exit without prompt
          confirm-close-surface = false;
          macos-option-as-alt = true;
          command = (if lcars.shell.fish.enable then "fish" else "zsh");
          keybind = [
            # Free up some keys
            "ctrl+,=unbind"
            "alt+0=unbind"
            "alt+1=unbind"
            "alt+2=unbind"
            "alt+3=unbind"
            "alt+4=unbind"
            "alt+5=unbind"
            "alt+6=unbind"
            "alt+7=unbind"
            "alt+8=unbind"
            "alt+9=unbind"
            "alt+digit_0=unbind"
            "alt+digit_1=unbind"
            "alt+digit_2=unbind"
            "alt+digit_3=unbind"
            "alt+digit_4=unbind"
            "alt+digit_5=unbind"
            "alt+digit_6=unbind"
            "alt+digit_7=unbind"
            "alt+digit_8=unbind"
            "alt+digit_9=unbind"
          ] ++ lib.optionals pkgs.stdenv.isDarwin [
            # Fix for MacOS keys
            "alt+left=unbind"
            "alt+right=unbind"
          ];
        };
      };
    };
  };
}
