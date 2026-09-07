--DO NOT EDIT. Auto generated from current stylix theme during deploy
require('mini.base16').setup({
  use_cterm = true,
  palette = {
    base00 = '#000000',
    base01 = '#1c1f24',
    base02 = '#2c313a',
    base03 = '#434852',
    base04 = '#565c64',
    base05 = '#abb2bf',
    base06 = '#b6bdca',
    base07 = '#c8ccd4',
    base08 = '#ef596f',
    base09 = '#d19a66',
    base0A = '#e5c07b',
    base0B = '#89ca78',
    base0C = '#2bbac5',
    base0D = '#61afef',
    base0E = '#d19a66',
    base0F = '#be5046'
  }
})

-- Set overrides for hl groups
-- Using the command for this one, so we can just change the existing one, instead of replacing it
vim.cmd "highlight NeogitDiffDeleteCursor guifg='#ef596f' gui=bold"

