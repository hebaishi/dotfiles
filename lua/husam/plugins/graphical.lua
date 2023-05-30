return {
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
