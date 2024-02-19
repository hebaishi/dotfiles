return {
  {
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
      { "<leader>tr", ":TunnellRange<CR>",  mode = { "v" }, desc = "Tunnell range" },
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
