
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable native LSP completion with autotrigger (Neovim 0.11+).
    -- Autotrigger fires after LSP trigger characters (.  ->  ::  etc.).
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })

    -- Combined omnifunc: LSP items + snippet items in one popup.
    vim.bo[ev.buf].omnifunc = 'v:lua._lsp_snippet_omnifunc'

    -- <C-n>/<C-p>: when the popup is already open just navigate it.
    -- When it is not open, fire <C-x><C-o> (omnifunc / LSP) to open it.
    -- Subsequent presses of <C-n>/<C-p> then navigate the popup normally.
    vim.keymap.set('i', '<C-n>', function()
      if vim.fn.pumvisible() == 1 then return '<C-n>' end
      return '<C-x><C-o>'
    end, { expr = true, buffer = ev.buf, desc = "Next completion / trigger LSP" })

    vim.keymap.set('i', '<C-p>', function()
      if vim.fn.pumvisible() == 1 then return '<C-p>' end
      return '<C-x><C-o>'
    end, { expr = true, buffer = ev.buf, desc = "Prev completion / trigger LSP" })

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
-- <CR>: confirm the selected completion item without inserting a newline.
-- Falls back to a normal <CR> when the popup is not open or nothing is selected.
vim.keymap.set('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ 'selected' }).selected ~= -1 then
    return '<C-y>'
  end
  return '<CR>'
end, { expr = true, desc = 'Confirm completion / newline' })

-- Combined omnifunc: merges LSP completions with snippet completions so both
-- appear in the same popup.  Defined as a global so the omnifunc string
-- 'v:lua._lsp_snippet_omnifunc' can reference it.
--
-- NOTE: We deliberately do NOT delegate to `vim.lsp.omnifunc`.  That function
-- is asynchronous: in its findstart=1 phase it returns -2 to tell Vim "I'll
-- call complete() myself later", which makes Vim skip the findstart=0 phase
-- entirely.  As a result any items we appended in findstart=0 (our snippets)
-- were never used.  Instead we drive a *synchronous* LSP request here and reuse
-- Neovim's own result-conversion helper so LSP + snippet items share one popup.
_G._lsp_snippet_omnifunc = function(findstart, base)
  local line = vim.api.nvim_get_current_line()
  local cursor_col = vim.fn.col('.') - 1            -- byte index of cursor (0-based)
  local line_to_cursor = line:sub(1, cursor_col)
  local word_boundary = vim.fn.match(line_to_cursor, '\\k*$')  -- 0-based byte col

  if findstart == 1 then
    -- If the isfname-bounded token under the cursor contains '/', treat it
    -- as a path and return the path start — the same boundary <C-x><C-f> uses.
    local path_col = vim.fn.match(line_to_cursor, [=[\f*$]=])
    if line_to_cursor:sub(path_col + 1):find('/') then
      return path_col
    end
    return word_boundary
  end

  local items = {}

  -- ── LSP items (synchronous request, reusing Neovim's converter) ──────────
  local ok_lsp, Completion = pcall(require, 'vim.lsp.completion')
  local clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/completion' })
  if ok_lsp and Completion._convert_results and #clients > 0 then
    local lnum = vim.fn.line('.') - 1               -- 0-based line
    for _, client in ipairs(clients) do
      local enc = client.offset_encoding or 'utf-16'
      local params = vim.lsp.util.make_position_params(0, enc)
      local responses = client:request_sync('textDocument/completion', params, 1000, 0)
      local result = responses and responses.result
      if result and #(result.items or result) > 0 then
        local matches, server_boundary = Completion._convert_results(
          line, lnum, cursor_col, client.id, word_boundary, nil, result, enc)
        -- If the server completes from an earlier column than our findstart,
        -- prepend the gap text so insertion at `word_boundary` stays correct.
        if server_boundary ~= nil and server_boundary < word_boundary then
          local gap = line:sub(server_boundary + 1, word_boundary)
          for _, m in ipairs(matches) do
            m.word = gap .. m.word
          end
        end
        vim.list_extend(items, matches)
      end
    end
  end

  -- ── Snippet items from nvim-snippets ─────────────────────────────────────
  local ok, Snippets = pcall(require, 'snippets')
  if ok then
    local ft_snippets = Snippets.load_snippets_for_ft(vim.bo.filetype) or {}
    for prefix, snip in pairs(ft_snippets) do
      if base == '' or vim.startswith(prefix, base) then
        local body = type(snip.body) == 'table'
          and table.concat(snip.body, '\n')
          or  (snip.body or '')
        table.insert(items, {
          word        = prefix,
          menu        = '[snip]',
          info        = snip.description or body,
          kind        = 'S',
          user_data   = { snippet_body = body },
          _is_snippet = true,
        })
      end
    end
  end

  -- ── Path / file completions ───────────────────────────────────────────────
  -- Active when the base contains a '/' or starts with a recognised path prefix
  -- (~, ., ..). Uses the same getcompletion('file') engine as <C-x><C-f>.
  if base:find('/') or base:match('^[~/.]') then
    local dir_part  = base:match('^(.*/)') or ''
    local name_part = base:match('[^/]*$') or ''

    local paths = vim.fn.getcompletion(base, 'file')

    -- getcompletion() follows the same glob rules as the shell and skips
    -- dotfiles unless the name-part of `base` already starts with '.'.
    -- Probe again with '.' appended to the directory so hidden entries
    -- are always included, then filter to those matching `name_part`.
    if not name_part:match('^%.') then
      for _, h in ipairs(vim.fn.getcompletion(dir_part .. '.', 'file')) do
        local tail = h:match('[^/]*/?$') or h
        if name_part == '' or vim.startswith(tail, name_part) then
          table.insert(paths, h)
        end
      end
    end

    local seen = {}
    for _, path in ipairs(paths) do
      if not seen[path] then
        seen[path] = true
        local is_dir = vim.fn.isdirectory(vim.fn.expand(path)) == 1
        table.insert(items, {
          word = path,
          menu = is_dir and '[dir]' or '[file]',
          kind = 'F',
        })
      end
    end
  end

  -- ── Rank items so the best matches for `base` come first ─────────────────
  -- Vim keeps the omnifunc order, so without this snippets (appended last)
  -- always sink to the bottom even when they match better than LSP items.
  if base ~= '' then
    local lower_base = base:lower()
    local function score(item)
      local word = item.word or ''
      local lw = word:lower()
      local s = 0
      if word == base then s = s + 100             -- exact match
      elseif lw == lower_base then s = s + 90 end   -- exact, case-insensitive
      if vim.startswith(word, base) then s = s + 50  -- prefix match
      elseif vim.startswith(lw, lower_base) then s = s + 40 end
      if item._is_snippet then s = s + 5 end         -- nudge snippets ahead on ties
      return s
    end
    -- Stable sort by descending score, then shorter word (closer to base).
    for i, item in ipairs(items) do item._idx = i end
    table.sort(items, function(a, b)
      local sa, sb = score(a), score(b)
      if sa ~= sb then return sa > sb end
      local la, lb = #(a.word or ''), #(b.word or '')
      if la ~= lb then return la < lb end
      return a._idx < b._idx
    end)
    for _, item in ipairs(items) do item._idx = nil end
  end

  return items
end

-- CompleteDone: handle both snippet expansion and function () insertion.
vim.api.nvim_create_autocmd('CompleteDone', {
  group = vim.api.nvim_create_augroup('LspCompletionParen', { clear = true }),
  callback = function()
    local item = vim.v.completed_item
    if not item or vim.tbl_isempty(item) then return end

    -- ── Snippet expansion ────────────────────────────────────────────────
    local snippet_body = vim.tbl_get(item, 'user_data', 'snippet_body')
    if snippet_body then
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local word = item.word or ''
      -- Remove the prefix word that was inserted, then expand the full snippet
      vim.api.nvim_buf_set_text(0, row - 1, col - #word, row - 1, col, {})
      vim.snippet.expand(snippet_body)
      return
    end

    -- ── Function () insertion ─────────────────────────────────────────────
    local lsp_item = vim.tbl_get(item, 'user_data', 'nvim', 'lsp', 'completion_item')
    if not lsp_item then return end

    -- Method = 2, Function = 3, Constructor = 4
    local kind = lsp_item.kind
    if kind ~= 2 and kind ~= 3 and kind ~= 4 then return end

    -- insertTextFormat 2 = snippet; Neovim expands it (including any `()`) automatically
    if lsp_item.insertTextFormat == 2 then return end

    -- Skip if the word already contains '('
    if (item.word or ''):find('%(') then return end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { '()' })
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
  end,
})

-- Auto-trigger path completion (<C-x><C-f>) whenever '/' is typed in insert
-- mode and no popup is already visible.  Works in every filetype.
vim.api.nvim_create_autocmd('InsertCharPre', {
  group = vim.api.nvim_create_augroup('PathAutoComplete', { clear = true }),
  callback = function()
    if vim.v.char ~= '/' then return end
    vim.schedule(function()
      if vim.fn.pumvisible() == 1 then return end
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('<C-x><C-f>', true, true, true),
        'n', false
      )
    end)
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
vim.diagnostic.config({ virtual_lines = { current_line = true } })
