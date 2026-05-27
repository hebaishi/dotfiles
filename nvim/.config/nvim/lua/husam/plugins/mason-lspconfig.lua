return {
  "williamboman/mason-lspconfig.nvim",
  config = function()
    vim.lsp.config('*', {
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
    })
    require('mason-lspconfig').setup()
  end,
  dependencies = {
    "neovim/nvim-lspconfig"
  }
}
