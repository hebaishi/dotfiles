vim.opt.smartindent = true
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.cmd(':set relativenumber')
vim.cmd('set makeprg=cmake\\ --build\\ build\\ --target\\ all')

-- Map kj to escape in insert and visual modes
vim.keymap.set('i', 'kj', '<Esc>', { noremap = true, silent = true })
vim.keymap.set('v', 'kj', '<Esc>', { noremap = true, silent = true })

vim.g.markdown_fenced_languages = { 'html', 'python', 'lua', 'vim', 'typescript', 'javascript', 'json', 'cpp', 'toml' }
-- Workaround for removing the signcolumn from new terminal windows
-- Can be removed post 0.11.0
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.signcolumn = "no"
  end,
})
