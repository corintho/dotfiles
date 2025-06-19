---@type LazySpec
return {
  {
    "pineapplegiant/spaceduck",
    branch = "dev",
    dependencies = {
      {
        "AstroNvim/astroui",
        ---@type AstroUIOpts
        opts = {
          highlights = {
            spaceduck = { -- a table of overrides/changes when applying the astrotheme theme
              FlashLabel = { link = "EyelinerPrimary" },
            },
          },
        },
      },
    },
  },
}
