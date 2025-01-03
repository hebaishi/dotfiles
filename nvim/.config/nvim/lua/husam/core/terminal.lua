local state = {
  floating = {
    buf = -1,
    win = -1
  }
}
local function create_floating_terminal(opts)
  -- Calculate dimensions
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create buffer
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- Window options
  local win_opts = {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'single'
  }

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.api.nvim_buf_set_keymap(buf, 't', '<leader>tt', '<cmd>FloatTerminal<CR>', { noremap = true, silent = true })

  return { buf = buf, win = win }
end

vim.api.nvim_create_user_command('FloatTerminal', function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_terminal { buf = state.floating.buf }
    if vim.bo[state.floating.buf].buftype ~= 'terminal' then
      vim.cmd.term()
      vim.cmd('startinsert')
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end, {})

vim.keymap.set('n', '<leader>tt', '<cmd>FloatTerminal<CR>')
