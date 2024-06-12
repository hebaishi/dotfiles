return {
  "navarasu/onedark.nvim",
  config = function()
    require("onedark").setup({
      style = 'deep'
    })
    require('onedark').load()
    vim.cmd.colorscheme = "onedark"
  end
}
