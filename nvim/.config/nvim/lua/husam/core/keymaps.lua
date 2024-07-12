vim.keymap.set('n', '<Leader>dg', function()
  vim.cmd(':Telescope diagnostics')
end, {})
vim.keymap.set('n', '<Leader>bb', function()
  vim.cmd(':Telescope buffers')
end, {})
vim.keymap.set('n', '<F3>', function()
  vim.lsp.buf.code_action({apply=true})
end, {})
vim.keymap.set('n', '<leader>fe', function()
	vim.cmd(':NvimTreeToggle')
end, {})
vim.keymap.set('n', '<leader>sf', function()
	vim.cmd(':NvimTreeFindFile')
end, {})
vim.keymap.set('n', '<leader>gg', function()
	vim.cmd(':Neogit')
end, {})
vim.keymap.set('n', '<F12>', function()
  vim.cmd(':cclose')
end,{})
vim.keymap.set('n', '<Leader>db', function()
  vim.cmd(':NvimTreeClose')
  require("dapui").toggle()
end,{})
vim.keymap.set('n', '<F8>', function()
  local status_ok, _ = pcall( vim.cmd, ':cn')
  if status_ok == false then
    vim.cmd(':crewind')
  end
end,{})
vim.keymap.set('n', '<F9>', function()
  require('dap').toggle_breakpoint()
end,{})
vim.keymap.set('n', '<F11>', function()
  require('dap').step_into()
end,{})
vim.keymap.set('n', '<F10>', function()
  require('dap').step_over()
end,{})
local async_command = 'cmake --build build --target all'
vim.keymap.set('n', '<F7>', function()
  vim.cmd(':copen')
  vim.cmd(':AsyncRun ' .. async_command)
end,{})
vim.keymap.set('n', '<F2>', function()
  vim.ui.input({ prompt = 'Enter makeprg command: ' }, function(input)
    async_command = input
  end)
end,{})
vim.keymap.set('n', '<S-F7>', function()
  vim.cmd(':cclose')
end,{})
vim.keymap.set('n', '<Leader>tt', function()
  vim.cmd([[
  :bo split
  :term
  ]])
end,{})

for i = 1, 5 do
  vim.keymap.set('n', '<A-' .. tostring(i) .. '>', function()
    if vim.loop.os_uname().sysname == 'Linux' then
      require("harpoon.tmux").sendCommand(tostring(i), i)
      require("harpoon.tmux").sendCommand(tostring(i), '\n')
    else
      local cmd = require("harpoon").get_term_config().cmds[i]
      local buffers = vim.api.nvim_list_bufs()

      -- Iterate through the buffers and filter out the terminal buffers
      local terminal_buffers = {}
      for _, bufnr in ipairs(buffers) do
          local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
          if buftype == 'terminal' then
              table.insert(terminal_buffers, bufnr)
          end
      end
      local terminal_job_id = vim.api.nvim_buf_get_var(terminal_buffers[i], "terminal_job_id")
      vim.api.nvim_chan_send(terminal_job_id, cmd .. "\r\n")
    end
  end, {})
end
