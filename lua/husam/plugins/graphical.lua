return {
  {
    "stevearc/dressing.nvim",
    config = true
  },
  {
    "nvim-lualine/lualine.nvim",
    config = true
  },
  {
    'projekt0n/github-nvim-theme',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd('colorscheme github_dark_high_contrast')
    end,
  }
}
