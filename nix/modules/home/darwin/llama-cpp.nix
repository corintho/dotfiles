{
  config,
  pkgs,
  lib,
  username,
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
        "-c"
        "0"
      ]
      ++ model.extraArgs;
    in
    "${llamaBin} ${lib.concatStringsSep " " args}";

  modelConfigs = builtins.mapAttrs (name: model: {
    cmd = mkCmd model;
    proxy = "http://127.0.0.1:\${PORT}";
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
