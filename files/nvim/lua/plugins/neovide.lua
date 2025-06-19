if not vim.g.neovide then
  return {} -- do nothing if not in a Neovide session
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      g = { -- configure vim.g variables
        -- configure scaling
        neovide_scale_factor = 1.0,
        -- configure padding
        neovide_padding_top = 0,
        neovide_padding_bottom = 0,
        neovide_padding_right = 0,
        neovide_padding_left = 0,
        -- disable cursor animation
        neovide_cursor_animation_length = 0,
        -- fix pasting for OSX
        neovide_input_macos_option_key_is_meta = "both",
        neovide_input_use_logo = 1,
      },
    },
  },
}
