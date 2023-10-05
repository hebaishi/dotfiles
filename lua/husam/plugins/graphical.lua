return {
  {
    "stevearc/dressing.nvim",
    config = true
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = { theme = "monokai-nightasty" },
      })
    end
  },
  {
    "polirritmico/monokai-nightasty.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local black = '#000000'
      vim.opt.background = "dark"                -- The theme has `dark` and `light` styles
      require("monokai-nightasty").setup({
        dark_style_background = black,           -- default, dark, transparent, #color
        light_style_background = "default",      -- default, dark, transparent, #color
        terminal_colors = false,                 -- Set the colors used when opening a `:terminal`
        color_headers = true,                    -- Enable header colors for each header level (h1, h2, etc.)
        hl_styles = {
          floats = 'dark',                       -- default, dark, transparent
          sidebars = 'dark',                     -- default, dark, transparent
        },
        sidebars = { "qf", "help", "NvimTree" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
        lualine_bold = true,                     -- Lualine headers will be bold or regular.
        lualine_style = "dark",                  -- "dark", "light" or "default" (Follows dark/light style)

        on_colors = function(colors)
          colors.bg_sidebar = colors.black
          colors.bg_float = colors.black
        end,

        --   ---@param highlights Highlights
        --   ---@param colors ColorScheme
        on_highlights = function(highlights, colors)
          highlights.TelescopeNormal = { bg = colors.black }
          highlights.WinSeparator = { fg = colors.white }
        end,
      })

      vim.cmd([[colorscheme monokai-nightasty]])
    end
  }
}
