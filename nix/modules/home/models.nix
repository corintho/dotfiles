{ lib, ... }: {
  options.lcars.models = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          modelPath = lib.mkOption {
            type = lib.types.str;
            description = "Path to the GGUF model file.";
          };
          mmprojPath = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Path to multimodal projection file (optional).";
          };
          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Extra arguments for llama-server (e.g. --jinja, -fa on).";
          };
          environment = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Per-model environment variables for the inference server (e.g. CUDA_VISIBLE_DEVICES).";
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "Human-readable name for display in clients.";
          };
          tools = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether the model supports tool/function calling.";
          };
          reasoning = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the model supports reasoning.";
          };
        };
      }
    );
    default = { };
    description = ''
      Local llama.cpp models available on this system.
      Each entry automatically generates:
      - A route in llama-swap config
      - A provider model entry in opencode
    '';
  };
}
