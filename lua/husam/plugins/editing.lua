return {
  "mg979/vim-visual-multi",
  "L3MON4D3/LuaSnip",
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
