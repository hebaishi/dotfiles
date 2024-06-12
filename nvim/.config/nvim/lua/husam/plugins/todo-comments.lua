return {
  "folke/todo-comments.nvim",
  keys = {
    { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "Show TODO items" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    'nvim-telescope/telescope.nvim'
  },
  config = true
}
