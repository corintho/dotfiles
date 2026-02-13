{ pkgs, ... }: {
  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;
    settings = {
      enabled_providers = [ "github-copilot" "openrouter" "ollama" "lm-studio" "llamacpp" ];
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options = { baseURL = "http://localhost:11434/v1"; };
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
      };
    };
  };
}
