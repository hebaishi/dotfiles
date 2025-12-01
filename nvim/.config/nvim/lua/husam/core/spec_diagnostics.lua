-- lua/spec_diagnostics.lua
--
-- Spec Diagnostics: check numbered markdown headings against C/C++ source
-- and emit diagnostics for spec items that have no implementation hits.

local M = {}

local ns = vim.api.nvim_create_namespace("spec_diagnostics")

-- Matches:
--   # 1. [REQ-001] Some text
--   ## [FEAT-FOO-2] Some optional text
--   # 1.1.[ID] text
-- Captures: hashes ("##"), number ("1.1." or ""), id ("FEAT-FOO-2"), text ("Some optional text")
local heading_pattern = "^(#+)%s+([%d%.]*)%s*%[([%w_.-]+)%]%s*(.*)$"

---@class SpecItem
---@field id string       -- e.g. "REQ-001" (the ID in brackets)
---@field number string   -- e.g. "1.2." (the leading number, optional)
---@field text string     -- heading text after the id
---@field level integer   -- heading level (# -> 1, ## -> 2, ...)
---@field lnum integer    -- 0-based line number

---@param bufnr integer
---@return SpecItem[]
local function get_spec_items(bufnr)
  print('Inside get spec items')
  local items = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    local hashes, spec_number, spec_id, text = line:match(heading_pattern)
    if hashes and spec_id then
      table.insert(items, {
        id = spec_id,
        number = spec_number or "",
        text = text or "",
        level = #hashes,
        lnum = i - 1,         -- diagnostics use 0-based line numbers
      })
    end
  end

  return items
end

-- Async ripgrep search:
--   term: string to search for (e.g. "1.1.1")
--   callback: function(found:boolean)
--
-- We search *.c and *.cpp files. You can tweak globs/extensions if needed.
---@param term string
---@param callback fun(found: boolean)
local function search_repo(term, callback)
  -- If you want stricter tagging in code, change `term` to e.g. "SPEC:" .. term
  local args = {
    "--fixed-strings",
    "--ignore-case",
    term,
    "--glob",
    "*.c",
    "--glob",
    "*.cpp",
  }

  -- Try to detect project root via LSP or fallback to current working directory.
  local cwd = vim.loop.cwd()
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf })
  if #clients > 0 and clients[1].config and clients[1].config.root_dir then
    cwd = clients[1].config.root_dir
  end

  local stdout = vim.loop.new_pipe(false)
  local handle

  handle = vim.loop.spawn("rg", {
    args = args,
    stdio = { nil, stdout, nil },
    cwd = cwd,
  }, function(code, _)
    stdout:close()
    handle:close()
    -- If rg exited with 0 and produced any output, we treat as found.
    local found = (code == 0)
    callback(found)
  end)

  stdout:read_start(function(err, data)
    if err then
      -- In case of error, just treat as not found and log once.
      vim.schedule(function()
        vim.notify("spec_diagnostics: rg error: " .. err, vim.log.levels.ERROR)
      end)
      return
    end
    -- We don't actually need the contents, just whether rg succeeded.
    if not data then
      return
    end
  end)
end

-- Main entry point: run spec diagnostics on current buffer.
function M.run()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  -- Optional guard: only run on markdown
  if ft ~= "markdown" and ft ~= "md" then
    vim.notify("SpecDiagnostics: buffer is not markdown (filetype=" .. ft .. ")", vim.log.levels.WARN)
    return
  end

  -- Clear previous diagnostics for this buffer/namespace
  vim.diagnostic.reset(ns, bufnr)

  local items = get_spec_items(bufnr)
  if #items == 0 then
    vim.notify("SpecDiagnostics: no numbered spec headings found", vim.log.levels.INFO)
    return
  end

  local pending = #items
  local diagnostics = {}
  local cancelled = false

  -- If user leaves buffer or changes it drastically, you might want to cancel.
  -- For now we keep it simple and just complete the run.

  for _, item in ipairs(items) do
    local term = item.id

    search_repo(term, function(found)
      if cancelled then
        return
      end

      if not found then
        local msg = "Spec item " .. item.number .. " (" .. item.id .. ") is not implemented"
        if item.text ~= "" then
          msg = msg .. ": " .. item.text
        end

        table.insert(diagnostics, {
          bufnr = bufnr,
          lnum = item.lnum,
          col = 0,
          severity = vim.diagnostic.severity.WARN,
          message = msg,
          source = "spec_diagnostics",
        })
      end

      pending = pending - 1
      if pending == 0 then
        -- Apply diagnostics when all searches are done
        vim.schedule(function()
          if not cancelled then
            vim.diagnostic.set(ns, bufnr, diagnostics, {})
            vim.notify("SpecDiagnostics: updated (" .. #diagnostics .. " missing items)", vim.log.levels.INFO)
          end
        end)
      end
    end)
  end
end

-- Optional: expose a function to clear diagnostics manually
function M.clear()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
end

M.get_spec_items = get_spec_items

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "md" },
    callback = function(args)
        local bufnr = args.buf
        vim.api.nvim_buf_create_user_command(bufnr, "SpecDiagnostics", function()
            M.run()
        end, { desc = "Run spec diagnostics against C/C++ sources" })

        vim.api.nvim_buf_create_user_command(bufnr, "SpecDiagnosticsClear", function()
            M.clear()
        end, { desc = "Clear spec diagnostics" })
    end,
})

return M
