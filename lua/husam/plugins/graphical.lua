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
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd(':colorscheme moonfly')
    end
  }
}
