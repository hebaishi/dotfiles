return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.4',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-fzf-native.nvim',
  },
  config = function()
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    require('telescope').setup({
      defaults = {
        file_ignore_patterns = {
          "^.git/",
          "*/node_modules/",
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
    require('telescope').load_extension('fzf')
    vim.keymap.set('n', '<leader>sm', require('husam.config.telescope.multigrep').setup, { desc = 'Multigrep' })
    vim.keymap.set('n', '<leader>si', require('husam.config.telescope.gitlab_issues').setup, { desc = 'Search Gitlab issues' })
  end
}
