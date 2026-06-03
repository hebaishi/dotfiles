return {
  "williamboman/mason-lspconfig.nvim",
  config = function()
    require('mason-lspconfig').setup()
  end,
  dependencies = {
    "neovim/nvim-lspconfig"
  }
}
