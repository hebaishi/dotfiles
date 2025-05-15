return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "b0o/schemastore.nvim"
  },
  config = function()
    vim.keymap.set('n', '<Leader>xx', function()
      vim.cmd("w")
      vim.cmd("source %")
    end, { desc = "Execute current file" })
    require 'lspconfig'.lua_ls.setup {
      settings = {
        Lua = {
          runtime = {
            -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
            version = 'LuaJIT',
          },
          diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = { 'vim' },
          },
          workspace = {
            -- Make the server aware of Neovim runtime files
            library = vim.api.nvim_get_runtime_file("", true),
          },
          -- Do not send telemetry data containing a randomized but unique identifier
          telemetry = {
            enable = false,
          },
        },
      },
    }
    require('lspconfig').clangd.setup {
      settings = {
        ['clangd'] = {},
      },
    }
    require 'lspconfig'.vtsls.setup {}
    require 'lspconfig'.jsonls.setup {
      settings = {
        json = {
          schemas = {
            {
              fileMatch = { "launch.json" },
              url = "https://raw.githubusercontent.com/mfussenegger/dapconfig-schema/master/dapconfig-schema.json"
            }
          }
        }
      }
    }

    require 'lspconfig'.rust_analyzer.setup {}
    require 'lspconfig'.pylsp.setup {
      settings = {
        pylsp = {
          plugins = {
            pycodestyle = {
              ignore = {
                'E111',
                'E121',
              },
              maxLineLength = 120
            }
          }
        }
      }
    }
    require('lspconfig').yamlls.setup {
      settings = {
        yaml = {
          schemas = {
            ["https://gitlab.com/gitlab-org/gitlab/-/raw/v14.10.0-ee/app/assets/javascripts/editor/schema/ci.json?ref_type=tags"] = ".gitlab-ci.yml"
          },
        },
      }
    }
    require 'lspconfig'.bashls.setup {}
    require 'lspconfig'.marksman.setup {}
    require 'lspconfig'.dartls.setup {}
  end
}
