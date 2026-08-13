return {
  "jbyuki/venn.nvim",
  keys = {
    {
      "<leader>v",
      function()
        vim.g.venn_enabled = not vim.g.venn_enabled
        if vim.g.venn_enabled then
          -- Draw a line with nHJKL
          vim.keymap.set("n", "J", "<C-v>j:VBox<CR>", { buffer = true })
          vim.keymap.set("n", "K", "<C-v>k:VBox<CR>", { buffer = true })
          vim.keymap.set("n", "L", "<C-v>l:VBox<CR>", { buffer = true })
          vim.keymap.set("n", "H", "<C-v>h:VBox<CR>", { buffer = true })
          -- Draw a box using visual mode
          vim.keymap.set("v", "f", ":VBox<CR>", { buffer = true })
          print("venn.nvim enabled")
        else
          vim.cmd("mapclear <buffer>")
          print("venn.nvim disabled")
        end
      end,
      desc = "Toggle venn.nvim (draw diagrams)",
    },
  },
  config = function()
    vim.g.venn_enabled = false
  end,
}
