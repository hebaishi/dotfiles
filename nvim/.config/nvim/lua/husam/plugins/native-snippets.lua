return {
  "garymjr/nvim-snippets",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    friendly_snippets = true,
    create_autocmd   = true,   -- load snippets per-filetype automatically
    create_cmp_source = false, -- cmp is removed; do not attempt to register a cmp source
    -- Extend C++ snippets with C snippets
    extended_filetypes = { cpp = { "c" } },
  },
  config = function(_, opts)
    -- Add personal snippet directory if it exists
    local personal = "/home/hebaishi/snippets"
    if vim.fn.isdirectory(personal) == 1 then
      opts.search_paths = opts.search_paths or {}
      table.insert(opts.search_paths, personal)
    end

    require("snippets").setup(opts)

    -- Load per-project .vscode snippets on startup and on directory change.
    --
    -- NOTE: nvim-snippets' register_snippets() / scan_for_snippets() only picks
    -- up files matching `*.json`, so VS Code `*.code-snippets` files are
    -- silently ignored. We therefore register the files directly into
    -- Snippets.registry, keyed by the filetype derived from the file name
    -- (e.g. cpp.code-snippets -> cpp).
    local function try_load_project_snippets()
      local vscode_dir = vim.fn.getcwd() .. "/.vscode"
      if vim.fn.isdirectory(vscode_dir) ~= 1 then return end

      local files = vim.fn.globpath(vscode_dir, "*.code-snippets", false, true)
      vim.list_extend(files, vim.fn.globpath(vscode_dir, "*.json", false, true))

      local added = false
      for _, f in ipairs(files) do
        -- ft = first dotted component of the basename: cpp.code-snippets -> cpp
        local ft = vim.fn.fnamemodify(f, ":t"):match("^([^.]+)")
        if ft then
          Snippets.registry[ft] = Snippets.registry[ft] or {}
          if not vim.tbl_contains(Snippets.registry[ft], f) then
            table.insert(Snippets.registry[ft], f)
            added = true
          end
        end
      end

      if added then
        Snippets.clear_cache()
      end
    end

    vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
      group = vim.api.nvim_create_augroup("ProjectSnippets", { clear = true }),
      callback = try_load_project_snippets,
    })

    -- Tab: jump forward through snippet placeholders; otherwise insert a tab
    vim.keymap.set({ 'i', 's' }, '<Tab>', function()
      if vim.snippet.active({ direction = 1 }) then
        return '<Cmd>lua vim.snippet.jump(1)<CR>'
      end
      return '<Tab>'
    end, { expr = true, desc = "Jump to next snippet placeholder" })

    -- S-Tab: jump backward through snippet placeholders
    vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
      if vim.snippet.active({ direction = -1 }) then
        return '<Cmd>lua vim.snippet.jump(-1)<CR>'
      end
      return '<S-Tab>'
    end, { expr = true, desc = "Jump to previous snippet placeholder" })
  end,
}
