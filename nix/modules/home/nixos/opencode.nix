{
  ...
}:
{
  xdg.configFile."opencode/plugins/override-conciseness.ts".source =
    ../opencode/plugins/override-conciseness.ts;

  programs.opencode = {
    settings = {
      model = "opencode/deepseek-v4-flash-free";
      agent = {
        plan.model = "opencode/deepseek-v4-flash-free";
        build.model = "opencode/deepseek-v4-flash-free";
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
