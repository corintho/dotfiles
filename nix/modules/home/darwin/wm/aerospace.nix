{ pkgs, ... }: {
  config = {
    programs.aerospace = {
      enable = true;
      package = pkgs.unstable.aerospace;
      userSettings =
        builtins.fromTOML (builtins.readFile ./aerospace/aerospace.toml);
    };
  };
}
