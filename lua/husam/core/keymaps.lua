local Hydra = require('hydra')

Hydra({
   name = 'Resize Window',
   mode = 'n',
   body = '<leader>r',
   heads = {
      { '+', '<C-W><C-+>' },
      { '-', '<C-W><C-->' },
      { '>', '<C-W><C->>' },
      { '<', '<C-W><C-<>' },
   }
})
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
vim.keymap.set('n', '<A-Left>', function()
	vim.cmd([[
	:let key = nvim_replace_termcodes("<C-w>", v:true, v:false, v:true)
	:call nvim_feedkeys(key, 'n', v:false)
	:call nvim_feedkeys('h', 'n', v:false)
	]])
end,{})
vim.keymap.set('n', '<A-Right>', function()
	vim.cmd([[
	:let key = nvim_replace_termcodes("<C-w>", v:true, v:false, v:true)
	:call nvim_feedkeys(key, 'n', v:false)
	:call nvim_feedkeys('l', 'n', v:false)
	]])
end,{})
vim.keymap.set('n', '<A-Up>', function()
	vim.cmd([[
	:let key = nvim_replace_termcodes("<C-w>", v:true, v:false, v:true)
	:call nvim_feedkeys(key, 'n', v:false)
	:call nvim_feedkeys('k', 'n', v:false)
	]])
end,{})
vim.keymap.set('n', '<A-Down>', function()
	vim.cmd([[
	:let key = nvim_replace_termcodes("<C-w>", v:true, v:false, v:true)
	:call nvim_feedkeys(key, 'n', v:false)
	:call nvim_feedkeys('j', 'n', v:false)
	]])
end,{})
vim.keymap.set('n', '<F12>', function()
  vim.cmd(':cclose')
end,{})
vim.keymap.set('n', '<Leader>db', function()
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
vim.keymap.set('n', 't', function ()
  local current_window = vim.fn.win_getid()
  require('leap').leap { target_windows = { current_window } }
end)
vim.keymap.set('n', '<leader>ha', function ()
  require("harpoon.mark").add_file()
end)
vim.keymap.set('n', '<A-j>', function ()
  require("harpoon.ui").nav_next()
end)
vim.keymap.set('n', '<A-k>', function ()
  require("harpoon.ui").nav_prev()
end)
vim.keymap.set('n', '<leader>hh', function ()
  require("harpoon.ui").toggle_quick_menu()
end)

for i = 1, 5 do
  vim.keymap.set('n', '<A-' .. tostring(i) .. '>', function()
    require("harpoon.tmux").sendCommand(tostring(i), i)
    require("harpoon.tmux").sendCommand(tostring(i), '\n')
  end, {})
end

vim.keymap.set('n', '<leader>hc', function()
  require('harpoon.cmd-ui').toggle_quick_menu()
end, {})
