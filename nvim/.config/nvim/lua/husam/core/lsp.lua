
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Goto declaration" })
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = "Goto definition" })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover" })
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = ev.buf, desc = "Implementation" })
    vim.keymap.set('n', '<C-s>', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = "Signature help" })
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { buffer = ev.buf, desc = "Add Workspace folder" })
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, { buffer = ev.buf, desc = "Remove workspace folder" })
    vim.keymap.set('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, { buffer = ev.buf, desc = "List workspace folders" })
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, { buffer = ev.buf, desc = "Type Definition" })
    vim.keymap.set('n', '<leader>sr', vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename symbol" })
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Action" })
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = ev.buf, desc = "Find references" })
    vim.keymap.set('n', '<leader>bf', function()
      vim.lsp.buf.format { async = true }
    end, { buffer = ev.buf, desc = "Format buffer" })
  end,
})
local signs = {
  Error = " ",
  Warn = " ",
  Hint = " ",
  Information = " "
}

for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = hl})
end
