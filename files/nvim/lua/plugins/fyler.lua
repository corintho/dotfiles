---@type LazySpec
return {
  "A7Lavinraj/fyler.nvim",
  dependencies = {
    "echasnovski/mini.icons",
    {
      "AstroNvim/astrocore",
      opts = {
        mappings = {
          n = {
            ["<Leader>y"] = { "<Cmd>Fyler<CR>", desc = "Fyler" },
          },
        },
      },
    },
  },
  cmd = "Fyler",
  opts = {},
}
