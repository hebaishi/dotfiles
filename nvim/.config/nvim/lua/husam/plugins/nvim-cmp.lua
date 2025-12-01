return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-nvim-lua",
    "windwp/nvim-autopairs",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp-signature-help",
  },
  config = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    require('husam.config.nvim-cmp.launch_json_source')
    require('husam.config.nvim-cmp.spec_source')

    cmp.setup({
      snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
          -- vim.fn["luasnip#anonymous"](args.body) -- For `luasnip` users.
          require('luasnip').lsp_expand(args.body)   -- For `luasnip` users.
          -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
          -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        end,
      },
      window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),   -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- they way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
            -- elseif has_words_before() then
            --  cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = 'spec' },
        { name = 'launch_json'},
        { name = 'nvim_lsp' },
        { name = 'nvim_lsp_document_symbol' },
        { name = 'nvim_lua' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = 'nvim_lsp_signature_help' },
        { name = 'cmdline' }
      }, {
        { name = 'buffer' },
      })
    })
    -- Set configuration for specific filetype.
    cmp.setup.filetype('gitcommit', {
      sources = cmp.config.sources({
        { name = 'cmp_git' },   -- You can specify the `cmp_git` source if you were installed it.
      }, {
        { name = 'buffer' },
      })
    })

    local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    local handlers = require('nvim-autopairs.completion.handlers')

    cmp.event:on(
      'confirm_done',
      cmp_autopairs.on_confirm_done({
        filetypes = {
          -- "*" is a alias to all filetypes
          ["*"] = {
            ["("] = {
              kind = {
                cmp.lsp.CompletionItemKind.Function,
                cmp.lsp.CompletionItemKind.Method,
              },
              handler = handlers["*"]
            }
          },
          lua = {
            ["("] = {
              kind = {
                cmp.lsp.CompletionItemKind.Function,
                cmp.lsp.CompletionItemKind.Method
              },
              ---@param char string
              ---@param item table item completion
              ---@param bufnr number buffer number
              ---@param rules table
              ---@param commit_character table<string>
              handler = function(char, item, bufnr, rules, commit_character)
                -- Your handler function. Inpect with print(vim.inspect{char, item, bufnr, rules, commit_character})
              end
            }
          },
          -- Disable for tex
          tex = false
        }
      })
    )
  end
}
