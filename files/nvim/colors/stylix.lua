--DO NOT EDIT. Auto generated from current stylix theme during deploy
require('mini.base16').setup({
  use_cterm = true,
  palette = {
    base00 = '#0c0b0a',
    base01 = '#1a1816',
    base02 = '#2b2825',
    base03 = '#6e6960',
    base04 = '#a8a29b',
    base05 = '#e8e8ec',
    base06 = '#f5f5f7',
    base07 = '#ffffff',
    base08 = '#ff5570',
    base09 = '#ffc942',
    base0A = '#b599ff',
    base0B = '#52e8a0',
    base0C = '#7ab8cc',
    base0D = '#5cd9ff',
    base0E = '#ffc942',
    base0F = '#ff8c42'
  }
})

-- Set overrides for hl groups
-- Using the command for this one, so we can just change the existing one, instead of replacing it
vim.cmd "highlight NeogitDiffDeleteCursor guifg='#ff5570' gui=bold"

