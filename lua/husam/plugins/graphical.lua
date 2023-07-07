return {
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = true
  },
  {
    "nvim-lualine/lualine.nvim",
    config = true
  },
  {
    "tanvirtin/monokai.nvim",
    config = function()
      require('monokai').setup {
        italics = false
      }
      vim.cmd(':colorscheme monokai')
    end
  },
}
