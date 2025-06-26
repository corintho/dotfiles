{ lib, pkgs, ... }: {
  options.lcars.shell.fish = lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Fish shell configuration.";
        };
        pkg = lib.mkOption {
          type = lib.types.package;
          default = pkgs.fish;
          description = "Fish shell package to use.";
        };
      };
    };
    default = {
      enable = false;
      pkg = pkgs.fish;
    };
    description = "Fish shell configuration options for LCARS.";
  };
}
