---@type LazySpec
return {
  {
    "Exafunction/codeium.nvim",
    enabled = function()
      return false
      -- local jit = require "jit"
      -- return jit.os ~= "OSX"
    end,
    cmd = "Codeium",
    event = "LspAttach",
    dependencies = {
      "AstroNvim/astrocore",
      ---@type AstroCoreOpts
      opts = {
        options = {
          g = {
            codeium_enabled = true,
          },
        },
        mappings = {
          n = {
            ["<leader>ac"] = {
              function()
                vim.g.codeium_enabled = not vim.g.codeium_enabled
                print("Codeium is now " .. (vim.g.codeium_enabled and "enabled" or "disabled"))
              end,
              desc = " Toggle codeium",
            },
          },
        },
        autocmds = {
          lsp_attach = {
            {
              event = "LspAttach",
              desc = "Add codeium to competion, if enabled",
              nested = true, -- trigger other autocommands as buffers open
              callback = function()
                local cmp = require "cmp"
                local sources = cmp.get_config().sources
                if vim.g.codeium_enabled and sources then
                  table.insert(sources, 1, {
                    name = "codeium",
                    soure_index = 2,
                  })
                end
              end,
            },
          },
        },
      },
    },
    config = true,
  },
}
