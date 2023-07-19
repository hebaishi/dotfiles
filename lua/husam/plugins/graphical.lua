return {
  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      vim.opt.list = true
      vim.opt.listchars:append "space:⋅"
      vim.opt.listchars:append "eol:↴"
      require("indent_blankline").setup({
        show_end_of_line = true,
        space_char_blankline = " ",
        indent_blankline_filetype_exclude = {
          "lspinfo",
          "packer",
          "checkhealth",
          "help",
          "man",
          "Neogitstatus"
        }
      }
    )
    end
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
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
