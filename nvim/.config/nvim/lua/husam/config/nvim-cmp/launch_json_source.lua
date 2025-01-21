local source = {}
local has_cmp, cmp = pcall(require, 'cmp')

if not has_cmp then return end

-- Common VSCode variables
local vscode_variables = {
  { label = "${workspaceFolder}",         documentation = "The path of the folder opened in VSCode" },
  { label = "${workspaceFolderBasename}",
                                            documentation =
    "The name of the folder opened in VSCode without any slashes (/)" },
  { label = "${file}",                    documentation = "The current opened file" },
  { label = "${fileWorkspaceFolder}",     documentation = "The current opened file's workspace folder" },
  { label = "${relativeFile}",            documentation = "The current opened file relative to workspaceFolder" },
  { label = "${relativeFileDirname}",     documentation = "The current opened file's dirname relative to workspaceFolder" },
  { label = "${fileBasename}",            documentation = "The current opened file's basename" },
  { label = "${fileBasenameNoExtension}", documentation = "The current opened file's basename with no file extension" },
  { label = "${fileDirname}",             documentation = "The current opened file's dirname" },
  { label = "${fileExtname}",             documentation = "The current opened file's extension" },
  { label = "${lineNumber}",              documentation = "The current selected line number in the active file" },
  { label = "${selectedText}",            documentation = "The current selected text in the active file" },
}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.setup = function(config)
end

source.get_trigger_characters = function()
  return { '$', '/' }
end

source.complete = function(self, params, callback)
  local line_to_cursor = params.context.cursor_line:sub(1, params.context.cursor.col)

  -- Check if we're in a launch.json file
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("launch.json$") then
    callback({ items = {} })
    return
  end

  -- Case 1: Variable completion after $
  if line_to_cursor:match("%${%w*}$") then
    callback({ items = vscode_variables })
    return
  end

  -- Case 2: Path completion after ${workspaceFolder}/
  local workspace_path_pattern = "${workspaceFolder}/(.*)\"$"
  local partial_path = line_to_cursor:match(workspace_path_pattern)

  if partial_path then
    local items = {}
    local workspace_path = vim.fn.getcwd()
    local search_dir = workspace_path

    -- If partial_path contains a directory, adjust search_dir
    local last_slash = partial_path:match("(.+)/")
    if last_slash then
      search_dir = workspace_path .. "/" .. last_slash
      partial_path = partial_path:sub(#last_slash + 2)
    end

    local scan = require('plenary.scandir')
    local paths = scan.scan_dir(search_dir, {
      hidden = true,
      depth = 3, -- Adjust depth as needed
      search_pattern = partial_path .. ".*"
    })

    for _, path in ipairs(paths) do
      local relative_path = path:sub(#workspace_path + 2)
      local is_directory = vim.fn.isdirectory(path) == 1

      table.insert(items, {
        label = relative_path,
        kind = is_directory and cmp.lsp.CompletionItemKind.Folder or cmp.lsp.CompletionItemKind.File,
        -- Add trailing slash for directories
        textEdit = {
          newText = relative_path .. (is_directory and "/" or ""),
          range = {
            start = {
              line = params.context.cursor.row - 1,
              character = params.context.cursor.col - #partial_path - 1
            },
            ["end"] = {
              line = params.context.cursor.row - 1,
              character = params.context.cursor.col - 1
            }
          }
        }
      })
    end

    callback({ items = items })
    return
  end

  callback({ items = {} })
end

-- Register the source
require('cmp').register_source('launch_json', source.new())
