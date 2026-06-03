-- launch_json_source.lua
-- Provides completion for VSCode launch.json variable placeholders and
-- workspace-relative paths.  Registered as the buffer's `omnifunc` whenever
-- a buffer named **/launch.json is opened; trigger with <C-x><C-o>.
--
-- No external dependencies — uses the native Neovim omnifunc mechanism.

local M = {}

local vscode_variables = {
  { word = "${workspaceFolder}",         info = "The path of the folder opened in VSCode" },
  { word = "${workspaceFolderBasename}", info = "The name of the folder opened in VSCode without any slashes (/)" },
  { word = "${file}",                    info = "The current opened file" },
  { word = "${fileWorkspaceFolder}",     info = "The current opened file's workspace folder" },
  { word = "${relativeFile}",            info = "The current opened file relative to workspaceFolder" },
  { word = "${relativeFileDirname}",     info = "The current opened file's dirname relative to workspaceFolder" },
  { word = "${fileBasename}",            info = "The current opened file's basename" },
  { word = "${fileBasenameNoExtension}", info = "The current opened file's basename with no file extension" },
  { word = "${fileDirname}",             info = "The current opened file's dirname" },
  { word = "${fileExtname}",             info = "The current opened file's extension" },
  { word = "${lineNumber}",              info = "The current selected line number in the active file" },
  { word = "${selectedText}",            info = "The current selected text in the active file" },
}

-- omnifunc contract: when findstart==1 return the column start of the current
-- completion token; when findstart==0 return a list of completion items.
function M.omnifunc(findstart, base)
  local line   = vim.api.nvim_get_current_line()
  local col    = vim.api.nvim_win_get_cursor(0)[2]  -- 0-based
  local before = line:sub(1, col)

  if findstart == 1 then
    -- Case 1: completing a ${...} variable — find the opening "${"
    local s = before:find("%${%w*$")
    if s then return s - 1 end  -- convert to 0-based

    -- Case 2: path token after ${workspaceFolder}/
    if before:match("%${workspaceFolder}/") then
      local s2 = before:find("[%w%.%-%_/]*$")
      if s2 then return s2 - 1 end
    end

    return -2  -- no completion available
  end

  -- findstart == 0: return matching items

  -- Case 1: VSCode variable completion
  if before:match("%${%w*$") then
    local items = {}
    for _, v in ipairs(vscode_variables) do
      if base == "" or v.word:find(base, 1, true) then
        table.insert(items, { word = v.word, info = v.info, menu = "[vscode]" })
      end
    end
    return items
  end

  -- Case 2: workspace-relative path completion
  local partial = before:match("%${workspaceFolder}/(.*)$")
  if partial then
    local workspace = vim.fn.getcwd()
    local dir       = workspace
    local prefix    = partial
    local last_sep  = partial:match("^(.*)/[^/]*$")

    if last_sep then
      dir    = workspace .. "/" .. last_sep
      prefix = partial:sub(#last_sep + 2)
    end

    local items  = {}
    local ok, entries = pcall(vim.fn.readdir, dir)
    if ok then
      for _, entry in ipairs(entries) do
        if prefix == "" or entry:sub(1, #prefix) == prefix then
          local full   = dir .. "/" .. entry
          local is_dir = vim.fn.isdirectory(full) == 1
          local rel    = (last_sep and last_sep .. "/" or "") .. entry
          table.insert(items, {
            word = rel .. (is_dir and "/" or ""),
            menu = is_dir and "[dir]" or "[file]",
          })
        end
      end
    end
    return items
  end

  return {}
end

-- Expose a global trampoline so the omnifunc string in v:lua can reference
-- this function without the module-path hyphen quoting problem.
_G.__launch_json_omnifunc = M.omnifunc

-- Register this omnifunc for every launch.json buffer
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group   = vim.api.nvim_create_augroup("LaunchJsonCompletion", { clear = true }),
  pattern = "*/launch.json",
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.__launch_json_omnifunc"
  end,
})

return M
