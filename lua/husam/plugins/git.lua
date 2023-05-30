return {
  {
    "TimUntersberger/neogit",
    config = function()
      require('neogit').setup {
        integrations = {
          diffview = true
        }
      }
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    config = true
  },
  "sindrets/diffview.nvim",
}
