{ pkgs, pkgs-unstable, ... }: {
  environment.systemPackages = with pkgs; [ base16-builder ];
  programs.bazecor = {
    enable = true;
    package = pkgs-unstable.bazecor;
  };

  users.users.corintho = {
    uid = 1000;
    extraGroups = [ "input" ];
  };
}
