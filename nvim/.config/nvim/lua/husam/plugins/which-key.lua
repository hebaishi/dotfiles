return {
  "folke/which-key.nvim",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
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
    local async_command = 'cmake --build build --target all'
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
      { "<leader>d",   group = "debug" },
      { "<leader>s",   group = "search" },
      { '<leader>p',   'o<ESC>p',                                                       desc = 'Paste on new line below' },
      { '<leader>P',   'O<ESC>p',                                                       desc = 'Paste on new line above' },
      { '[t',          '<cmd>tabprevious<CR>',                                          desc = 'Previous Tab' },
      { ']t',          '<cmd>tabnext<CR>',                                              desc = 'Next Tab' },
      { '<leader>T',   '<cmd>tabnew<CR>',                                               desc = 'New Tab' },
      { '<leader>tc',  '<cmd>tabclose<CR>',                                             desc = 'Close Tab' },
      { '<leader>ta',  function() require("taskwarrior_nvim").browser({ "ready" }) end, desc = 'Close Tab' },
      { "<leader>sh",  builtin.help_tags,                                               desc = 'Search Help' },
      { "<leader>sk",  builtin.keymaps,                                                 desc = 'Search Keymaps' },
      { "<leader>sf",  builtin.find_files,                                              desc = 'Search Files' },
      { "<leader>ss",  builtin.builtin,                                                 desc = 'Search Select Telescope' },
      { "<leader>sw",  builtin.grep_string,                                             desc = 'Search current Word' },
      { "<leader>sg",  builtin.live_grep,                                               desc = 'Search by Grep' },
      { "<leader>sG",  builtin.git_status,                                              desc = 'Search Git status' },
      { "<leader>sd",  builtin.diagnostics,                                             desc = 'Search Diagnostics' },
      { "<leader>sr",  builtin.resume,                                                  desc = 'Search Resume' },
      { "<leader>ne",  group = "neorg" },
      { "<leader>nei", function() vim.cmd("Neorg index") end,                           desc = 'Neorg index' },
      { "<leader>ner", function() vim.cmd("Neorg return") end,                          desc = 'Neorg return' },
      {
        "<leader>s.",
        builtin.oldfiles,
        desc =
        'Search Recent Files ("." for repeat)'
      },
      { "<leader>gy", function() require('gitlinker').get_buf_range_url('n') end, desc = 'Get git link' },
      {
        "<leader>gc",
        require('husam.core.gitlab_comments').get_mr_comments,
        desc =
        'Get comments for current MR'
      },
      {
        "<leader>cs",
        function() vim.cmd(":ClangdSwitchSourceHeader") end,
        desc =
        'Clangd Switch source/header'
      },
      { "<leader>o",  group = "ollama" },
      { "<leader>h",  group = "harpoon" },
      { "<leader>ha", harpoon.add_file,                                           desc = 'Harpoon Add file' },
      { "<leader>hn", require("harpoon.ui").nav_next,                             desc = 'Harpoon Navigate Next' },
      {
        "<leader>hp",
        require("harpoon.ui").nav_prev,
        desc =
        'Harpoon Navigate Previous'
      },
      {
        "<leader>hu",
        require("harpoon.ui").toggle_quick_menu,
        desc =
        'Harpoon Toggle Quick Menu'
      },
      { "<leader>hc",       require("harpoon.cmd-ui").toggle_quick_menu,   desc = 'Harpoon Toggle Cmd-UI' },
      { "<leader>i",        group = "icon" },
      { "<leader>in",       function() vim.cmd(":IconPickerNormal") end,   desc = 'Icon Picker Normal' },
      { "<leader>ii",       function() vim.cmd(":IconPickerInsert") end,   desc = 'Icon Picker Insert' },
      { "<leader>neo",      group = "neo" },
      { "<leader>gg",       function() vim.cmd(":Neogit") end,             desc = 'Neogit' },
      { "<leader>n",        group = "neotree" },
      { "<leader>nr",       function() vim.cmd(":Neotree reveal") end,     desc = 'Neotree reveal' },
      { "<leader>ng",       function() vim.cmd(":Neotree git_status") end, desc = 'Neotree git status' },
      { "<leader>nc",       function() vim.cmd(":Neotree close") end,      desc = 'Neotree close' },
      { "<leader>qc",       function() vim.cmd(":cclose") end,             desc = 'Close quickfix window' },
      { "<leader><leader>", '<C-^>',                                       desc = 'Alternate file' },
      { "<leader>m",        group = "makeprg" },
      {
        "<leader>mr",
        function()
          vim.cmd(':copen')
          vim.cmd(':AsyncRun ' .. async_command)
        end,
        desc = 'Makeprg Run'
      },
      {
        "<leader>ms",
        function()
          vim.ui.input({ prompt = 'Enter makeprg command: ' }, function(input)
            async_command = input
          end)
        end,
        desc = 'Makeprg set'
      },
    })
  end
}
