return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  lazy = false,
  config = function()
    require("catppuccin").setup({
      no_italic = true,
      term_colors = true,
      transparent_background = false,
      styles = {
        comments = {},
        conditionals = {},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
      },
      color_overrides = {
        mocha = {
          base = "#000000",
          mantle = "#000000",
          crust = "#000000",
        },
      },
      integrations = {
        telescope = {
          enabled = true,
          style = "nvchad",
        },
        dropbar = {
          enabled = true,
          color_mode = true,
        },
        gitsigns = true,
        nvimtree = true,
        leap = true,
        markdown = true,
        indent_blankline = {
          enabled = true,
          -- scope_color = "", -- catppuccin color (eg. `lavender`) Default: text
          colored_indent_levels = false,
        }
      },
    })
    vim.cmd.colorscheme "catppuccin-mocha"
  end
}
