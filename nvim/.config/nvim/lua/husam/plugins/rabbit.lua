return {
  "voxelprismatic/rabbit.nvim",
  event = "VeryLazy",
  config = function()
    require("rabbit").setup({})
  end
}
