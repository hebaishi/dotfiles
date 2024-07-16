local async_command = 'cmake --build build --target all'
vim.keymap.set('n', '<F7>', function()
  vim.cmd(':copen')
  vim.cmd(':AsyncRun ' .. async_command)
end, {})
vim.keymap.set('n', '<F2>', function()
  vim.ui.input({ prompt = 'Enter makeprg command: ' }, function(input)
    async_command = input
  end)
end, {})
