return {
  "navarasu/onedark.nvim",
  config = function()
    require('onedark').setup {
      style = 'darker',
      colors = {
        bg0 = "#000000", -- define a new color
        bg1 = "#111111", -- define a new color
        bg_d = "#000000", -- define a new color
      },
    }
    vim.cmd.colorscheme 'onedark'
    -- require('onedark').load()
  end
}
