return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
  },
  config = function()
    local wk = require("which-key")
    local builtin = require 'telescope.builtin'
    local harpoon = require 'harpoon'

    wk.register({
      s = {
        name = "search",
        h = { builtin.help_tags, '[S]earch [H]elp' },
        k = { builtin.keymaps, '[S]earch [K]eymaps' },
        f = { builtin.find_files, '[S]earch [F]iles' },
        s = { builtin.builtin, '[S]earch [S]elect Telescope' },
        w = { builtin.grep_string, '[S]earch current [W]ord' },
        g = { builtin.live_grep, '[S]earch by [G]rep' },
        d = { builtin.diagnostics, '[S]earch [D]iagnostics' },
        r = { builtin.resume, '[S]earch [R]esume' },
        ["."] = { builtin.oldfiles, '[S]earch Recent Files ("." for repeat)' }
      },
      h = {
        name= "harpoon",
        a = { harpoon.mark, '[H]arpoon [M]ark'},
        n = { require("harpoon.ui").nav_next, '[H]arpoon Navigate [N]ext'},
        p = { require("harpoon.ui").nav_prev, '[H]arpoon Navigate [P]revious'},
        m = { require("harpoon.ui").toggle_quick_menu, '[H]arpoon Toogle Quick [M]enu'},
        c = { require("harpoon.cmd-ui").toggle_quick_menu, '[H]arpoon [C]md-UI'}
      },
      c = {
        name = "clangd",
        s = { function() vim.cmd(":ClangdSwitchSourceHeader") end, "[C]langd [S]witch Source/Header"}
      }
    }, { prefix = "<leader>" })
  end
}
