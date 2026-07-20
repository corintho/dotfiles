{
  config,
  pkgs,
  lib,
  username,
  ...
}:

{
  home.packages = with pkgs.unstable; [
    open-webui
  ];

  launchd.agents."open-webui" = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.unstable.open-webui}/bin/open-webui"
        "serve"
        "--host"
        "127.0.0.1"
        "--port"
        "8083"
      ];
      EnvironmentVariables = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:1234";
        DATA_DIR = "/Users/${username}/.local/share/open-webui";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${username}/Library/Logs/open-webui.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/open-webui.log";
    };
  };
}
