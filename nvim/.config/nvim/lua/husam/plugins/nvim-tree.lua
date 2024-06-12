return {
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
  end
}
