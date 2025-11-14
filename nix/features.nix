{ pkgs, ... }: {
  lcars.shell.fish = {
    enable = true;
    package = pkgs.fish; # Omit or override if needed
  };
}
