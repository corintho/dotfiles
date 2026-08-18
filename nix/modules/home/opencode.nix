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
in
{
  xdg.configFile."opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${files}/opencode/AGENTS.md";

  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;
    settings = {
      share = "disabled";
      default_agent = "plan";
      enabled_providers = [
        "github-copilot"
        "opencode"
        "ollama"
        "lm-studio"
        "llamacpp"
        "llama.cpp"
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
