{
  config,
  pkgs,
  lib,
  files,
  ...
}:

let
  llmModels = config.lcars.models or { };

  mkModel =
    name: model:
    { inherit (model) name tools; } // lib.optionalAttrs model.reasoning { reasoning = true; };

  autoModels = lib.mapAttrs mkModel llmModels;

  # Mirror of nix/modules/home/nixos/koboldcpp.nix sanitize. KoboldCpp's router derives
  # /v1/models ids from the .kcpps filenames in --admindir (basename WITH the .kcpps
  # extension), so the raw lcars key can never select a model there.
  sanitize = k: builtins.replaceStrings [ "/" ":" " " "@" ] [ "_" "_" "_" "_" ] k;

  koboldModels = lib.mapAttrs' (
    name: model: lib.nameValuePair "${sanitize name}.kcpps" (mkModel name model)
  ) llmModels;
in
{
  xdg.configFile."opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/agents/AGENTS.md";

  programs.opencode = {
    enable = true;
    package = import ./opencode-cli-package.nix {
      inherit pkgs;
      system = pkgs.stdenv.hostPlatform.system;
    };
    settings = {
      share = "disabled";
      enabled_providers = [
        "github-copilot"
        "opencode"
        "ollama"
        "lm-studio"
        "llamacpp"
        "llama.cpp"
        "kobold"
      ];
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options = {
            baseURL = "http://localhost:11434/v1";
          };
          models = {
            "qwen3-vl:4b" = {
              name = "qwen3-vl:4b";
              reasoning = true;
              tools = true;
            };
            "dolphin3:latest" = {
              name = "dolphin3:latest";
              reasoning = true;
              tools = false;
            };
            "deepseek-r1:1.5b" = {
              name = "deepseek-r1:1.5b";
              reasoning = true;
              tools = false;
            };
            "qwen3:4b" = {
              name = "qwen3:4b";
              reasoning = true;
              tools = true;
            };
          };
        };
        "llama.cpp" = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama.cpp (local)";
          options = {
            baseURL = "http://127.0.0.1:1234/v1";
          };
          models = autoModels;
        };
        kobold = {
          npm = "@ai-sdk/openai-compatible";
          name = "KoboldCpp (local)";
          options = {
            baseURL = "http://127.0.0.1:5001/v1";
          };
          models = koboldModels;
        };
      };
      permission = {
        external_directory = {
          "/tmp/**" = "allow";
        };
        skill = {
          "*" = "allow";
        };
      };
    };
  };
}
