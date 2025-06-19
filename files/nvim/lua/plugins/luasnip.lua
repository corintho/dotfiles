--TODO: only do this if the plugin is enabled

---@type LazySpec
return {
  {
    "L3MON4D3/LuaSnip",
    config = function() require("luasnip.loaders.from_vscode").load_standalone { path = "project.code-snippets" } end,
  },
}
