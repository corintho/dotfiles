---@type LazySpec
return {
  {
    "mistricky/codesnap.nvim",
    build = "make",
    opts = {
      has_breadcrumbs = true,
      has_line_number = true,
      bg_color = "#535c68",
    },
  },
}
