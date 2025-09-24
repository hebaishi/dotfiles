local Path = require("plenary.path")
local scandir = require("plenary.scandir")

local function configure_clangd()
  local cwd = vim.fn.getcwd()
  local matches = scandir.scan_dir(cwd, {
    depth = 5,
    search_pattern = "compile_commands.json",
    hidden = true,
  })

  if #matches == 0 then
    vim.notify("No compile_commands.json found", vim.log.levels.WARN)
    return
  end

  local relative_matches = vim.tbl_map(function(match)
    return Path:new(match):make_relative()
  end, matches)

  matches = relative_matches

  local function write_clangd(path)
    local clangd_config = string.format("CompileFlags:\n  CompilationDatabase: %s\n", Path:new(path):parent():absolute())
    local clangd_file = Path:new(vim.fn.getcwd(), ".clangd")

    if clangd_file:exists() then
      local current = clangd_file:read()
      if current == clangd_config then
        vim.notify(".clangd already up to date", vim.log.levels.INFO)
        return
      end
    end

    clangd_file:write(clangd_config, "w")
    vim.notify("Updated .clangd to use: " .. path, vim.log.levels.INFO)
  end

  if #matches == 1 then
    write_clangd(matches[1])
  else
    vim.ui.select(matches, { prompt = "Select compile_commands.json:" }, function(choice)
      if choice then write_clangd(choice) end
    end)
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = configure_clangd,
})
