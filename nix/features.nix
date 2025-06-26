{ pkgs, ... }: {
  lcars.shell.fish = {
    enable = true;
    pkg = pkgs.fish; # Omit or override if needed
  };
}
