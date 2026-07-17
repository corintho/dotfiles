{ pkgs, username, ... }:

let
  gemmaModel = "/Users/${username}/.cache/huggingface/hub/models--ggml-org--gemma-4-E4B-it-GGUF/snapshots/6d556b1304a00d2a95a62f567bb2df5ff5abb936/gemma-4-E4B-it-Q8_0.gguf";
  gemmaMmproj = "/Users/${username}/.cache/huggingface/hub/models--ggml-org--gemma-4-E4B-it-GGUF/snapshots/6d556b1304a00d2a95a62f567bb2df5ff5abb936/mmproj-gemma-4-E4B-it-Q8_0.gguf";
  qwen3Model = "/Users/${username}/.cache/huggingface/hub/models--unsloth--Qwen3-14B-GGUF/snapshots/a04a82c4739b3ef5fa6da7d10261db2c67dd1985/Qwen3-14B-UD-Q4_K_XL.gguf";
  qwen2CoderModel = "/Users/${username}/.cache/huggingface/hub/models--unsloth--Qwen2.5-Coder-14B-Instruct-GGUF/snapshots/388f3f20271ef903bb2dbe7d8236158903e7edb3/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf";
  llamaBin = "${pkgs.unstable.llama-cpp}/bin/llama-server";

  llamaSwapConfig = pkgs.writeText "llama-swap-config.yaml" ''
    healthCheckTimeout: 120

    models:
      "ggml-org/gemma-4-E4B-it-GGUF:Q8_0":
        cmd: "${llamaBin} --model ${gemmaModel} --mmproj ${gemmaMmproj} --port ''${PORT} -ngl 99 -c 0"
        proxy: http://127.0.0.1:''${PORT}

      "unsloth/Qwen3-14B-GGUF:UD-Q4_K_XL":
        cmd: "${llamaBin} --model ${qwen3Model} --port ''${PORT} --jinja -ngl 99 -c 0 -fa on"
        proxy: http://127.0.0.1:''${PORT}

      "unsloth/Qwen2.5-Coder-14B-Instruct-GGUF:Q4_K_M":
        cmd: "${llamaBin} --model ${qwen2CoderModel} --port ''${PORT} --jinja -ngl 99 -c 0 -fa on"
        proxy: http://127.0.0.1:''${PORT}
  '';
in
{
  home.packages = with pkgs.unstable; [
    llama-swap
  ];

  launchd.agents."llama-cpp" = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.unstable.llama-swap}/bin/llama-swap"
        "--config"
        "${llamaSwapConfig}"
        "--listen"
        "127.0.0.1:1234"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${username}/Library/Logs/llama-cpp.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/llama-cpp.log";
    };
  };
}
