{ pkgs-unstable, ... }: {
  programs.bazecor = {
    enable = true;
    package = pkgs-unstable.bazecor;
  };

  users.users.corintho = {
    uid = 1000;
    extraGroups = [ "input" ];
  };
}
