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
    "tanvirtin/monokai.nvim",
    config = function()
      require('monokai').setup {
        italics = false
      }
      vim.cmd(':colorscheme monokai')
    end
  },
}
