return {
  paddings = 3,
  group_paddings = 5,

  icons = "NerdFont", -- Using NerdFont icons (changed from "sf-symbols")

  -- Font configuration for JetBrainsMono Nerd Font (installed via Nix)
  font = {
    text = "JetBrainsMono Nerd Font", -- Used for text
    numbers = "JetBrainsMono Nerd Font", -- Used for numbers
    style_map = {
      ["Regular"] = "Regular",
      ["Semibold"] = "Medium",
      ["Bold"] = "SemiBold",
      ["Heavy"] = "Bold",
      ["Black"] = "ExtraBold",
    },
  },
}
