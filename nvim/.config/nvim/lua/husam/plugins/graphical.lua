return {
  {
    "rcarriga/nvim-notify",
    config = function()
      vim.notify = require("notify")
    end
  },
  {
    "stevearc/dressing.nvim",
    config = true
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({})
    end
  },
  {
    "navarasu/onedark.nvim",
    config = function()
      require("onedark").setup({
        style = 'deep'
      })
      require('onedark').load()
      vim.cmd.colorscheme = "onedark"
    end
  }
}
