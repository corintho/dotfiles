{ pkgs, username, ... }:

let
  gemmaModel = "/Users/${username}/.cache/huggingface/hub/models--ggml-org--gemma-4-E4B-it-GGUF/snapshots/6d556b1304a00d2a95a62f567bb2df5ff5abb936/gemma-4-E4B-it-Q8_0.gguf";
  gemmaMmproj = "/Users/${username}/.cache/huggingface/hub/models--ggml-org--gemma-4-E4B-it-GGUF/snapshots/6d556b1304a00d2a95a62f567bb2df5ff5abb936/mmproj-gemma-4-E4B-it-Q8_0.gguf";
  llamaBin = "${pkgs.unstable.llama-cpp}/bin/llama-server";

  llamaSwapConfig = pkgs.writeText "llama-swap-config.yaml" ''
    healthCheckTimeout: 120

    models:
      "ggml-org/gemma-4-E4B-it-GGUF:Q8_0":
        cmd: "${llamaBin} --model ${gemmaModel} --mmproj ${gemmaMmproj} --port ''${PORT} -ngl 99 -c 0"
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
