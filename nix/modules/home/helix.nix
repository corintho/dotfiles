{ pkgs, ... }: {
  config = {
    programs = {
      helix = {
        enable = true;
        package = pkgs.unstable.helix;
      };
    };
  };
}
