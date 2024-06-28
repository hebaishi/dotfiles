return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup({
      options = {
        theme = "catppuccin",
        component_separators = '',
        section_separators = { left = '', right = '' },
      }
    })
    vim.cmd('set laststatus=3')
  end
}
