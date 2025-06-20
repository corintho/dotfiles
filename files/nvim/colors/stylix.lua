--DO NOT EDIT. Auto generated from current stylix theme during deploy
require('mini.base16').setup({
  use_cterm = true,
  palette = {
    base00 = '#0e121b',
    base01 = '#232a3b',
    base02 = '#203554',
    base03 = '#666688',
    base04 = '#444a77',
    base05 = '#ccdeff',
    base06 = '#f5f6fa',
    base07 = '#88bbff',
    base08 = '#ff2200',
    base09 = '#ff8800',
    base0A = '#ffaa00',
    base0B = '#00b844',
    base0C = '#88ccff',
    base0D = '#2255ff',
    base0E = '#ff8800',
    base0F = '#cc2233'
  }
})

-- Set overrides for hl groups
-- Using the command for this one, so we can just change the existing one, instead of replacing it
vim.cmd "highlight NeogitDiffDeleteCursor guifg='#ff2200' gui=bold"

