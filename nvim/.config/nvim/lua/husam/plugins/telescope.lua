return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.4',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    require('telescope').setup({
      defaults = {
        file_ignore_patterns = {
          "^.git/"
        }
      },
      pickers = {
        find_files = {
          hidden = true
        }
      },
      extensions = {
        fzf = {}
      }
    })
  end
}
