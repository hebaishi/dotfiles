return {
  "hebaishi/taskwarrior.nvim",
  config = function()
    vim.keymap.set("n", "<leader>tw", function()
      require("taskwarrior_nvim").browser({ "ready" })
    end, { desc = "TaskWarrior browser (ready)" })
  end,
}
