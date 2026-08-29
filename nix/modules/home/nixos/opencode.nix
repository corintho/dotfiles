{
  ...
}:
{
  xdg.configFile."opencode/plugins/override-conciseness.ts".source =
    ../opencode/plugins/override-conciseness.ts;

  programs.opencode = {
    settings = {
      agent = {
      };
      mcp = {
        browsermcp = {
          type = "local";
          command = [
            "npx"
            "-y"
            "@browsermcp/mcp@0.1.3"
          ];
          enabled = true;
        };
      };
    };
  };
}
