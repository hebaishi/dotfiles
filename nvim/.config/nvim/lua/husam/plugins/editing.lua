return {
  {
    "jghauser/mkdir.nvim",
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
            prompt = "$input. Only show the code. Enclose all code in triple backticks.",
            input_label = "> ",
            model = "llama3",
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
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("hardtime").setup({
        disable_mouse = false
      })
      vim.cmd(':set mouse=a')
    end
  },
  {
    "ziontee113/icon-picker.nvim",
    config = function()
      require("icon-picker").setup({ disable_legacy_commands = true })

      local opts = { noremap = true, silent = true }

      vim.keymap.set("n", "<Leader><Leader>i", "<cmd>IconPickerNormal<cr>", opts)
      vim.keymap.set("n", "<Leader><Leader>y", "<cmd>IconPickerYank<cr>", opts) --> Yank the selected icon into register
      vim.keymap.set("i", "<C-i>", "<cmd>IconPickerInsert<cr>", opts)
    end
  },
  {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "stevearc/dressing.nvim",   -- Recommended but not required. Better UI for pickers.
      "nvim-tree/nvim-web-devicons" -- Recommended but not required. Icons in discussion tree.
    },
    enabled = true,
    build = function() require("gitlab.server").build(true) end, -- Builds the Go binary
    config = function()
      require("gitlab").setup()
    end,
  }
}
