return {
  "folke/which-key.nvim",
  dependencies = {
    "echasnovski/mini.icons"
  },
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
  config = function()
    local wk = require("which-key")
    local builtin = require 'telescope.builtin'
    local harpoon = require 'harpoon'
    wk.setup({
      preset = "modern",
      icons = {
        rules = {
          { pattern = "git",      cat = "filetype", name = "git" },
          { pattern = "rabbit",   icon = "🐇",    color = "white" },
          { pattern = "start",    icon = "",     color = "cyan" },
          { pattern = "add",      icon = "",     color = "green" },
          { pattern = "debug",    icon = "",     color = "red" },
          { pattern = "switch",   icon = "",     color = "white" },
          { pattern = "ollama",   icon = "🦙",    color = "cyan" },
          { pattern = "next",     icon = "",     color = "green" },
          { pattern = "previous", icon = "",     color = "green" },
          { pattern = "pick",     icon = "👌",    color = "green" },
          { pattern = "tree",     icon = "",     color = "green" }
        }
      }
    })
    wk.add({
      { "<leader>d",  group = "debug" },
      { "<leader>s",  group = "search" },
      { "<leader>sh", builtin.help_tags,   desc = 'Search Help' },
      { "<leader>sk", builtin.keymaps,     desc = 'Search Keymaps' },
      { "<leader>sf", builtin.find_files,  desc = 'Search Files' },
      { "<leader>ss", builtin.builtin,     desc = 'Search Select Telescope' },
      { "<leader>sw", builtin.grep_string, desc = 'Search current Word' },
      { "<leader>sg", builtin.live_grep,   desc = 'Search by Grep' },
      { "<leader>sd", builtin.diagnostics, desc = 'Search Diagnostics' },
      { "<leader>sr", builtin.resume,      desc = 'Search Resume' },
      {
        "<leader>s.",
        builtin.oldfiles,
        desc =
        'Search Recent Files ("." for repeat)'
      },
      { "<leader>gy",  function() require('gitlinker').get_buf_range_url('n') end, desc = 'Get git link' },
      { "<leader>cs",  function() vim.cmd(":ClangdSwitchSourceHeader") end,        desc = 'Clangd Switch source/header' },
      { "<leader>ng",  function() vim.cmd(":Neogit") end,                          desc = 'Open Neogit' },
      { "<leader>o",   group = "ollama" },
      { "<leader>h",   group = "harpoon" },
      { "<leader>ha",  harpoon.add_file,                                           desc = 'Harpoon Add file' },
      { "<leader>hn",  require("harpoon.ui").nav_next,                             desc = 'Harpoon Navigate Next' },
      { "<leader>hp",  require("harpoon.ui").nav_prev,                             desc = 'Harpoon Navigate Previous' },
      { "<leader>hm",  require("harpoon.ui").toggle_quick_menu,                    desc = 'Harpoon Toggle Quick Menu' },
      { "<leader>hm",  require("harpoon.cmd-ui").toggle_quick_menu,                desc = 'Harpoon Toggle Cmd-UI' },
      { "<leader>i",   group = "icon" },
      { "<leader>in",  function() vim.cmd(":IconPickerNormal") end,                desc = 'Icon Picker Normal' },
      { "<leader>ii",  function() vim.cmd(":IconPickerInsert") end,                desc = 'Icon Picker Insert' },
      { "<leader>neo", group = "neo" },
      { "<leader>gg",  function() vim.cmd(":Neogit") end,                          desc = 'Neogit' },
      { "<leader>n",   group = "neotree" },
      { "<leader>nr",  function() vim.cmd(":Neotree reveal") end,                  desc = 'Neotree reveal' },
      { "<leader>ng",  function() vim.cmd(":Neotree git_status") end,              desc = 'Neotree git status' },
      {
        "[q",
        function()
          local status_ok, _ = pcall(vim.cmd, ':cp')
          if status_ok == false then
            vim.cmd(':clast')
          end
        end,
        desc = 'Previous quickfix item'
      },
      {
        "]q",
        function()
          local status_ok, _ = pcall(vim.cmd, ':cn')
          if status_ok == false then
            vim.cmd(':cfirst')
          end
        end,
        desc = 'Next quickfix item'
      },
      { "<leader>qc", function() vim.cmd(":cclose") end, desc = 'Close quickfix window' },
    })
  end
}
