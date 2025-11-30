{ pkgs, ... }: {
  config = {
    programs.aerospace = {
      enable = true;
      launchd.enable = true;
      package = pkgs.unstable.aerospace;
      settings =
        builtins.fromTOML (builtins.readFile ./aerospace/aerospace.toml);
    };
  };
}
