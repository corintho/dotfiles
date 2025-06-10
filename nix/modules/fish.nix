{ pkgs, ... }: {
  config = {

    xdg.configFile = { "fish/functions/zz.fish".source = ./fish/zz.fish; };
    programs = {
      fish = {
        enable = true;
        shellInit = "set -g fish_greeting";
        plugins = [
          {
            name = "autopair";
            src = pkgs.fishPlugins.autopair.src;
          }
          {
            name = "bang-bang";
            src = pkgs.fishPlugins.bang-bang.src;
          }
          {
            name = "fish-colored-man";
            src = pkgs.fetchFromGitHub {
              owner = "decors";
              repo = "fish-colored-man";
              rev = "1ad8fff696d48c8bf173aa98f9dff39d7916de0e";
              sha256 = "sha256-uoZ4eSFbZlsRfISIkJQp24qPUNqxeD0JbRb/gVdRYlA=";
            };
          }
          {
            name = "done";
            src = pkgs.fishPlugins.done.src;
          }
          {
            name = "sponge";
            src = pkgs.fishPlugins.sponge.src;
          }
        ];
      };
    };
  };
}

