local M = {}

local function get_all_spec_items()
  local all_items = {}
  local ok, spec_diagnostics = pcall(require, "husam.core.spec_diagnostics")
  if not ok or not spec_diagnostics.get_spec_items then return all_items end

  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = true })) do
    local ft = vim.bo[buf.bufnr] and vim.bo[buf.bufnr].filetype
    if ft == 'markdown' or ft == 'md' then
      for _, item in ipairs(spec_diagnostics.get_spec_items(buf.bufnr)) do
        table.insert(all_items, item)
      end
    end
  end
  return all_items
end

M.source = {
  name = "spec",
  filetype = { enable = { 'c', 'cpp' } }, -- Enable for C and C++ files
  get_trigger_characters = function()
    return { '-' }
  end,

  complete = function(_, params, callback)
    local line_to_cursor = params.context.cursor_line:sub(1, params.context.cursor.col)
    local current_word = line_to_cursor:match("([%w-]+)$")

    if not current_word or not (current_word:sub(1, 4) == 'Req-') then
      callback({})
      return
    end

    local spec_items = get_all_spec_items()
    local completions = {}
    for _, item in ipairs(spec_items) do
      table.insert(completions, {
        label = item.id,
        kind = vim.lsp.protocol.CompletionItemKind.Reference,
        documentation = {
          kind = "markdown",
          value = "#### " .. item.number .. "\n\n" .. item.text,
        },
      })
    end

    callback(completions)
  end,
}


require("cmp").register_source(M.source.name, M.source)

return M
