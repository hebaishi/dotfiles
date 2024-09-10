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
vim.g.markdown_fenced_languages = { 'html', 'python', 'lua', 'vim', 'typescript', 'javascript', 'json', 'cpp', 'toml' }
