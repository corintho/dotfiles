-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Set up custom filetypes
vim.filetype.add {
  extension = {
    ["code-snippets"] = "jsonc",
  },
  filename = {
    ["Podfile"] = "ruby",
  },
  -- pattern = {
  --   ["~/%.config/foo/.*"] = "fooscript",
  -- },
}

-- Enable per project vim options
vim.o.exrc = true

-- Setup for neovide
if vim.g.neovide == true then
  -- Proper setup for OSX
  local jit = require "jit"
  if jit.os == "OSX" then
    -- Fixes copy & paste using Cmd on OSX
    vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })
  end
end

pcall(require, "patches")
