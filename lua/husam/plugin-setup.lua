local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  "nvim-lualine/lualine.nvim",
  "ggandor/leap.nvim",
  "saadparwaiz1/cmp_luasnip",
  "L3MON4D3/LuaSnip",
  "TimUntersberger/neogit",
  "mg979/vim-visual-multi",
  "nvim-treesitter/nvim-treesitter",
  "tanvirtin/monokai.nvim",
  "lewis6991/gitsigns.nvim",
  "sindrets/diffview.nvim",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  "sakhnik/nvim-gdb",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/nvim-cmp",
  "skywind3000/asyncrun.vim",
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {"mfussenegger/nvim-dap"}
  },
  {
    "folke/trouble.nvim",
    dependencies = {"nvim-tree/nvim-web-devicons"}
  },
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.1',
     dependencies = { 'nvim-lua/plenary.nvim' }
  },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {

    sort_by = "case_sensitive",
    view = {
      width = 50,
    },
    renderer = {
      group_empty = true,
    },
    filters = {
      dotfiles = false,
    },
  }
  end,
}})
