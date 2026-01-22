--DO NOT EDIT. Auto generated from current stylix theme during deploy
require('mini.base16').setup({
  use_cterm = true,
  palette = {
    base00 = '#1d2021',
    base01 = '#3c3836',
    base02 = '#504945',
    base03 = '#665c54',
    base04 = '#bdae93',
    base05 = '#d5c4a1',
    base06 = '#ebdbb2',
    base07 = '#fbf1c7',
    base08 = '#fb4934',
    base09 = '#fe8019',
    base0A = '#fabd2f',
    base0B = '#b8bb26',
    base0C = '#8ec07c',
    base0D = '#83a598',
    base0E = '#fe8019',
    base0F = '#d65d0e'
  }
})

-- Set overrides for hl groups
-- Using the command for this one, so we can just change the existing one, instead of replacing it
vim.cmd "highlight NeogitDiffDeleteCursor guifg='#fb4934' gui=bold"

