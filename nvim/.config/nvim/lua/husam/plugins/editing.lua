return {
  {
    {
      "nomnivore/ollama.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      -- All the user commands added by the plugin
      cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },
      keys = {
        {
          "<leader>oo",
          ":<c-u>lua require('ollama').prompt()<cr>",
          desc = "ollama prompt",
          mode = { "n", "v" },
        },
        {
          "<leader>oG",
          ":<c-u>lua require('ollama').prompt('CodeGen2')<cr>",
          desc = "ollama Generate Code",
          mode = { "n", "v" },
        },
      },
      opts = {
        model = "codellama",
        url = "http://127.0.0.1:11434",
        serve = {
          on_start = false,
          command = "ollama",
          args = { "serve" },
          stop_command = "pkill",
          stop_args = { "-SIGTERM", "ollama" },
        },
        prompts = {
          CodeGen2 = {
            prompt = "$input. Write all code in a code block. Do not explain the code.",
            input_label = "> ",
            model = "codellama",
            action = "insert",
            extract = "```%w*\n(.-)```"
          }
        }
      }
    },
    "sourproton/tunnell.nvim",
    opts = {
      -- defaults are:
      cell_header = "# %%",
      tmux_target = "1",
    },

    -- to lazy-load on keymaps:
    keys = {
      -- suggestions for keymaps:
      -- { "<leader>tt", ":TunnellCell<CR>",   mode = { "n" }, desc = "Tunnell cell" },
      { "<leader>tr", ":TunnellRange<CR>", mode = { "v" }, desc = "Tunnell range" },
      -- { "<leader>tc", ":TunnellConfig<CR>", mode = { "n" }, desc = "Tunnell config" },
    },

    -- to lazy-load on commands:
    cmd = {
      "TunnellCell",
      "TunnellRange",
      "TunnellConfig",
    },
  },
  "mg979/vim-visual-multi",
  "jparise/vim-graphql",
  "L3MON4D3/LuaSnip",
  "hrsh7th/cmp-path",
  {
    "windwp/nvim-ts-autotag",
    config = true
  },
  {
    "ThePrimeagen/harpoon",
    config = true
  },
  {
    "windwp/nvim-autopairs",
    config = true
  },
  {
    "numToStr/Comment.nvim",
    config = true
  },
  {
    "kylechui/nvim-surround",
    config = true
  },
  {
    "saadparwaiz1/cmp_luasnip",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load({ paths = { "/home/hebaishi/snippets" } })
    end
  },
  {
    "ggandor/leap-spooky.nvim",
    config = true,
    dependencies = {
      "ggandor/leap.nvim"
    }
  },
  {
    "ggandor/leap.nvim",
    config = function()
      require('leap').add_default_mappings()
    end
  },
}
