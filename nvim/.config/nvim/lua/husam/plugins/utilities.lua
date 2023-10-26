return {
  "skywind3000/asyncrun.vim",
  "anuvyklack/hydra.nvim",
  "williamboman/mason.nvim",
  {
    "akinsho/toggleterm.nvim",
    config = true
  },
  {
    "RishabhRD/nvim-cheat.sh",
    config = function()
      vim.keymap.set('n', '<leader>cl', function()
        vim.cmd(':CheatList')
      end)
      vim.keymap.set('n', '<leader>ch', function()
        vim.cmd(':Cheat')
      end)
    end,
    dependencies = {
      "RishabhRD/popfix"
    }
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      local lspconfig = require('lspconfig')
      require('mason-lspconfig').setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({
            on_attach = lsp_attach,
            capabilities = lsp_capabilities,
          })
        end,
      })
    end,
    dependencies = {
      "neovim/nvim-lspconfig"
    }
  },
}
