return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.4',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    require('telescope').setup({
      extensions = {
        fzf = {
          fuzzy = true,                     -- false will only do exact matching
          override_generic_sorter = true,   -- override the generic sorter
          override_file_sorter = true,      -- override the file sorter
          case_mode = "smart_case",         -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        }
      }
    })
  end
}
