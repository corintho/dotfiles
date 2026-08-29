{
  config,
  pkgs,
  lib,
  ...
}:

let
  models = config.lcars.models or { };
  llamaBin = "${pkgs.unstable.llama-cpp}/bin/llama-server";
  yamlFmt = pkgs.formats.yaml { };

  mkCmd =
    model:
    let
      port = "\${PORT}";
      args = [
        "--model"
        model.modelPath
      ]
      ++ lib.optionals (model.mmprojPath != null) [
        "--mmproj"
        model.mmprojPath
      ]
      ++ [
        "--port"
        port
        "-ngl"
        (toString model.gpuLayers)
      ]
      ++ lib.optionals model.flashAttention [
        "-fa"
        "on"
      ]
      ++ lib.optionals model.jinja [
        "--jinja"
      ]
      ++ lib.optionals (model.kvQuant != null) [
        "--cache-type-k"
        model.kvQuant.k
        "--cache-type-v"
        model.kvQuant.v
      ]
      ++ [
        "--ctx-size"
        (toString model.contextSize)
      ]
      ++ model.extraArgs;
    in
    "${llamaBin} ${lib.concatStringsSep " " args}";

  modelConfigs = builtins.mapAttrs (name: model: {
    cmd = mkCmd model;
    proxy = "http://127.0.0.1:\${PORT}";
    # cudaDevices is the source of truth for CUDA device selection: when set it
    # overrides any CUDA_VISIBLE_DEVICES entry in environment. Models without it
    # keep their environment untouched (no regression).
    env =
      if model.cudaDevices or null != null then
        (lib.filter (s: !lib.hasPrefix "CUDA_VISIBLE_DEVICES=" s) model.environment)
        ++ [ "CUDA_VISIBLE_DEVICES=${model.cudaDevices}" ]
      else
        model.environment;
  }) models;

  llamaSwapConfig = yamlFmt.generate "llama-swap-config.yaml" {
    healthCheckTimeout = 120;
    models = modelConfigs;
  };
in
lib.mkIf (models != { }) {
  home.packages = with pkgs.unstable; [
    llama-cpp
    llama-swap
  ];

  systemd.user.services."llama-swap" = {
    Unit = {
      Description = "llama-swap AI model router";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${pkgs.unstable.llama-swap}/bin/llama-swap --config ${llamaSwapConfig} --listen 127.0.0.1:1234";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
