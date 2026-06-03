-- custom-completions.lua
-- Loads custom completion sources that were previously driven by nvim-cmp.
-- Each source sets up its own autocmds and uses the native Neovim
-- completion API (vim.fn.complete / omnifunc) instead.

require('husam.config.nvim-cmp.spec_source')
require('husam.config.nvim-cmp.launch_json_source')
