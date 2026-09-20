{ pkgs, lib, ... }: {
  config = {

    xdg.configFile = {
      "fish/functions/zz.fish".source = ./fish/zz.fish;
      "fish/functions/mr.fish".source = ./fish/mr.fish;
    };
    programs = {
      fish = {
        enable = true;
        shellInit = lib.mkMerge [
          "set -x SHELL /run/current-system/sw/bin/bash"
          (lib.mkIf pkgs.stdenv.isDarwin "fish_add_path /opt/homebrew/bin/")
        ];
        interactiveShellInit = ''
          set -g fish_greeting
          # Dynamic OPENCODE_API_KEY from the genuine opencode auth store.
          # Runtime-only: nothing is baked into the store at eval time.
          if test -z "$OPENCODE_API_KEY"; and test -r $HOME/.local/share/opencode/auth.json
            set -l _oc_key (python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.local/share/opencode/auth.json")))["opencode"]["key"])' 2>/dev/null)
            if test -n "$_oc_key"
              set -gx OPENCODE_API_KEY $_oc_key
            end
          end
        '';
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
