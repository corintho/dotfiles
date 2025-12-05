{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Custom scripts on path
    (writeShellApplication {
      name = "zed";
      text = ''
        env -u WAYLAND_DISPLAY ${pkgs.unstable.zed-editor}/bin/zeditor
      '';
    })
    # /Custom scripts on path
  ];
  programs.zed-editor = {
    enable = true;
    package = pkgs.unstable.zed-editor;
  };
}
