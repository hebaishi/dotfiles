require('husam.core.options')
require('husam.plugin-setup')
require('husam.core.keymaps')
require('husam.core.lsp')
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
