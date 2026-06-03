-- spec_source.lua
-- Provides completion for spec-item IDs (e.g. "Req-001") in C/C++ buffers.
-- Fires automatically via TextChangedI when the word under the cursor starts
-- with "Req-"; calls vim.fn.complete() with IDs gathered from all listed
-- markdown buffers.
--
-- No external dependencies — uses the native Neovim completion API.

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

-- Auto-trigger completion when the current word begins with "Req-"
vim.api.nvim_create_autocmd("TextChangedI", {
  group = vim.api.nvim_create_augroup("SpecCompletion", { clear = true }),
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local col  = vim.api.nvim_win_get_cursor(0)[2]  -- 0-based
    local before = line:sub(1, col)
    local word = before:match("([%w%-]+)$")

    if not word or word:sub(1, 4) ~= "Req-" then return end

    local spec_items = get_all_spec_items()
    if #spec_items == 0 then return end

    local items = {}
    for _, item in ipairs(spec_items) do
      table.insert(items, {
        word  = item.id,
        menu  = "[spec]",
        info  = "#### " .. item.number .. "\n\n" .. item.text,
        kind  = "r",  -- reference
      })
    end

    -- col is 0-based; complete() wants a 1-based column of where the word starts
    local start_col = col - #word + 1
    vim.fn.complete(start_col, items)
  end,
})

return M
