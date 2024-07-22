return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require('gitsigns').setup {
      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        local nav_hunk = function(position)
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gitsigns.nav_hunk(position)
          end
        end
        local nav_hunk_prev = function() nav_hunk('prev') end
        local nav_hunk_next = function() nav_hunk('next') end

        -- Navigation
        map('n', ']c', nav_hunk_next, { desc = "Next hunk" })
        map('n', '[c', nav_hunk_prev, { desc = "Previous hunk" })

        -- Actions
        map('n', '<leader>gs', gitsigns.stage_hunk, { desc = "Stage hunk" })
        map('n', '<leader>gr', gitsigns.reset_hunk, { desc = "Reset hunk" })
        map('v', '<leader>gs', function() gitsigns.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
          { desc = "Stage hunk" })
        map('v', '<leader>gr', function() gitsigns.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
          { desc = "Reset hunk" })
        map('n', '<leader>gS', gitsigns.stage_buffer, { desc = "Stage Buffer" })
        map('n', '<leader>gu', gitsigns.undo_stage_hunk, { desc = "Undo Stage Hunk" })
        map('n', '<leader>gR', gitsigns.reset_buffer, { desc = "Reset Buffer" })
        map('n', '<leader>gp', gitsigns.preview_hunk, { desc = "Preview hunk" })
        map('n', '<leader>gb', function() gitsigns.blame_line { full = true } end, { desc = "Blame line" })
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = "Toggle Current line blame" })
        map('n', '<leader>gd', gitsigns.diffthis, { desc = "Diff this" })
        map('n', '<leader>gD', function() gitsigns.diffthis('~') end, { desc = "Diff this" })
        map('n', '<leader>td', gitsigns.toggle_deleted, { desc = "Toggle deleted" })

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      end
    }
  end
}
