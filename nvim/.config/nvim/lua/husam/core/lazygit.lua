vim.keymap.set('n', '<Leader>lg', function()
  local Terminal = require('toggleterm.terminal').Terminal
  local lazygit_term = Terminal:new {
    cmd = "lazygit",
    direction = "tab",
    dir = ".",
  }
  lazygit_term:toggle()
end, {})
