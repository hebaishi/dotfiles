local function _is_visual_mode(m)
  return type(m) == "string" and string.upper(m) == "V"
      or string.upper(m) == "CTRL-V"
      or string.upper(m) == "<C-V>"
      or m == "\22"
end

function GitLineLog()
  -- Get the current buffer's file path
  local file_path = vim.fn.expand('%:p')

  -- Get current line number or visual selection range
  local m = vim.fn.mode()

  local l1 = nil
  local l2 = nil
  if _is_visual_mode(m) then
    vim.cmd([[execute "normal! \<ESC>"]])
    l1 = vim.fn.getpos("'<")[2]
    l2 = vim.fn.getpos("'>")[2]
  else
    l1 = vim.fn.getcurpos()[2]
    l2 = l1
  end
  local lstart = math.min(l1, l2)
  local lend = math.max(l1, l2)

  -- Build the git log command
  local cmd = string.format('git log -L %d,%d:%s && read -n1', lstart, lend, file_path)
  print(cmd)

  -- Create a new terminal buffer and execute the command
  vim.cmd('enew')                               -- Create new split
  vim.cmd('terminal ' .. cmd)
  vim.cmd('setlocal nonumber norelativenumber') -- Disable line numbers

  -- Start in insert mode
  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('GitLineLog', GitLineLog, { range = true })
vim.keymap.set('n', '<leader>gl', '<cmd>GitLineLog<CR>', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>gl', '<cmd>GitLineLog<CR>', { noremap = true, silent = true })
