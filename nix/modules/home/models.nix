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
          gpuLayers = lib.mkOption {
            type = lib.types.int;
            default = -1;
            description = "Number of layers to offload to the GPU (-1 = all). Engine-agnostic.";
          };
          contextSize = lib.mkOption {
            type = lib.types.int;
            default = 4096;
            description = "Context window size in tokens. Engine-agnostic.";
          };
          flashAttention = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable flash attention. Engine-agnostic.";
          };
          jinja = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Use the model's Jinja chat template (koboldcpp / llama.cpp).";
          };
          chatAdapter = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "chatml"
                "gemma"
              ]
            );
            default = null;
            description = "KoboldCpp Chat Completions Adapter preset for the OpenAI-compatible /v1 endpoint (chatml = Qwen ChatML, gemma = Gemma). Null = koboldcpp default (Alpaca fallback).";
          };
          useswa = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable sliding-window attention (koboldcpp).";
          };
          kvQuant = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  k = lib.mkOption {
                    type = lib.types.str;
                    description = "KV cache quantization type for K (llama.cpp only).";
                  };
                  v = lib.mkOption {
                    type = lib.types.str;
                    description = "KV cache quantization type for V (llama.cpp only).";
                  };
                };
              }
            );
            default = null;
            description = "KV cache quantization types (llama.cpp only).";
          };
          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Raw passthrough arguments for llama-server (llama.cpp escape hatch).";
          };
          environment = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Per-model environment variables for the inference server. For CUDA backends, a CUDA_VISIBLE_DEVICES entry here is superseded by cudaDevices when that is set.";
          };
          cudaDevices = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "CUDA device list for CUDA backends (sets CUDA_VISIBLE_DEVICES), e.g. \"0,1\". When set, overrides any CUDA_VISIBLE_DEVICES entry in environment. Null = backend default.";
          };
          tensorSplit = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.int);
            default = null;
            description = "KoboldCpp --tensor_split ratios across visible GPUs, e.g. [ 2 1 ] (proportional to VRAM).";
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
      Local inference models available on this system. Engine-agnostic:
      each backend (llama.cpp, koboldcpp, ...) translates these fields into
      its own native flags. Each entry automatically generates:
      - A route in llama-swap config (llama.cpp)
      - A .kcpps launcher config (koboldcpp, launched via kobold-select)
      - A provider model entry in opencode
    '';
  };
}
