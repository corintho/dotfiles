--DO NOT EDIT. Auto generated from current stylix theme during deploy
require('mini.base16').setup({
  use_cterm = true,
  palette = {
    base00 = '#0f0f1a',
    base01 = '#1a1a2e',
    base02 = '#2a2a3e',
    base03 = '#6c6c86',
    base04 = '#c0c0d0',
    base05 = '#d8d8e8',
    base06 = '#e8e8f4',
    base07 = '#ffffff',
    base08 = '#ff0055',
    base09 = '#ff9505',
    base0A = '#ffee00',
    base0B = '#00ff9f',
    base0C = '#00e8c6',
    base0D = '#00b4d8',
    base0E = '#ff9505',
    base0F = '#cd6320'
  }
})

-- Set overrides for hl groups
-- Using the command for this one, so we can just change the existing one, instead of replacing it
vim.cmd "highlight NeogitDiffDeleteCursor guifg='#ff0055' gui=bold"

