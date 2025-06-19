---@type LazySpec
return {
  {
    "code-biscuits/nvim-biscuits",
    lazy = false, --FIXME: There is currently a bug with LazyLoading: https://github.com/code-biscuits/nvim-biscuits/issues/47
    -- event = "LspAttach",
    opts = {
      show_on_start = true,
      cursor_line_only = true,
    },
    dependencies = {
      "AstroNvim/astrocore",
      ---@type AstroCoreOpts
      opts = {
        mappings = {
          n = {
            ["<Leader>uB"] = {
              function() require("nvim-biscuits").toggle_biscuits() end,
              desc = "󰆘 Toggle context",
            },
          },
        },
      },
    },
  },
}
