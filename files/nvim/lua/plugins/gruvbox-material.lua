---@type LazySpec
return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    dependencies = {
      "AstroNvim/astrocore",
      ---@type AstroCoreOpts
      opts = {
        options = {
          g = {
            gruvbox_material_background = "hard",
            gruvbox_material_foreground = "original",
          },
        },
      },
    },
  },
}
