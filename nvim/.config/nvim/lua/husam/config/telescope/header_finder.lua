-- fuzzy_header_finder.lua
-- A Neovim plugin to fuzzy search for header files from compile_commands.json

local M = {}
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')

local function get_compile_commands_path()
  local clangd_path = vim.fn.getcwd() .. "/.clangd"
  local compile_commands_path = nil

  if vim.fn.filereadable(clangd_path) == 1 then
    for line in io.lines(clangd_path) do
      local match = line:match("^%s*CompilationDatabase:%s*(.+)$")
      if match then
        compile_commands_path = vim.fn.fnamemodify(match, ":p") .. "/compile_commands.json"
        break
      end
    end
  end

  return compile_commands_path
end

-- Path to compile_commands.json
local default_compile_commands_path = get_compile_commands_path()

M.add_include = function(include_line)
  -- Get the current buffer
  local bufnr = vim.api.nvim_get_current_buf()

  -- Get all lines from the buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find the first line with '#include'
  local include_line_index = nil
  for i, line in ipairs(lines) do
    if line:match("#include") then
      include_line_index = i - 1 -- Convert to 0-based index
      break
    end
  end

  -- If no include line was found, set to insert at the top of the file
  if not include_line_index then
    include_line_index = 0
  end

  -- Insert the new include line above the first existing include
  vim.api.nvim_buf_set_lines(bufnr, include_line_index, include_line_index, false, { include_line })
end

-- Function to compute relative path between two files
local function get_relative_path(from_file, to_file)
  -- Get directory of source file
  local from_dir = vim.fn.fnamemodify(from_file, ':h')

  -- If paths are on different drives (Windows), use absolute path
  if vim.fn.has('win32') == 1 and string.sub(from_dir, 1, 1) ~= string.sub(to_file, 1, 1) then
    return to_file
  end

  -- Convert to absolute paths
  from_dir = vim.fn.fnamemodify(from_dir, ':p')
  to_file = vim.fn.fnamemodify(to_file, ':p')

  -- Find common prefix
  local i = 1
  while i <= math.min(#from_dir, #to_file) do
    if string.sub(from_dir, i, i) ~= string.sub(to_file, i, i) then
      break
    end
    i = i + 1
  end

  -- Find the last directory separator before the difference
  while i > 1 do
    if string.sub(from_dir, i, i) == '/' or string.sub(from_dir, i, i) == '\\' then
      break
    end
    i = i - 1
  end

  -- If we found a common root
  if i > 0 then
    local common_root = string.sub(from_dir, 1, i)
    local from_dir_rel = string.sub(from_dir, i + 1)
    local to_file_rel = string.sub(to_file, i + 1)

    -- Count directories to go up
    local up_count = 0
    for _ in string.gmatch(from_dir_rel, "[^/\\]+") do
      up_count = up_count + 1
    end

    -- Build relative path
    local rel_path = string.rep("../", up_count) .. to_file_rel
    return rel_path
  end

  -- Fallback to absolute path if no common root
  return to_file
end

-- Function to extract include paths from gcc/g++ command
local function extract_include_paths(command)
  local include_paths = {}
  -- Match both -I/path/to/include and -I /path/to/include formats
  for path in string.gmatch(command, "-I[ ]?([^ ]+)") do
    table.insert(include_paths, path)
  end

  -- Also try to capture system include paths which might be in angle brackets
  local system_paths = { "/usr/include", "/usr/local/include" }
  for _, path in ipairs(system_paths) do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(include_paths, path)
    end
  end

  return include_paths
end

-- Function to create a finder using ripgrep for on-demand searching
local function create_header_finder(include_paths)
  -- Create the ripgrep command
  -- We'll search for header file extensions across all include paths
  local rg_command = function(query)
    -- Escape the query
    local escaped_query = query:gsub("([^%w])", "\\%1")

    -- Build the command with all include paths
    local cmd = "rg --files"

    -- Add include paths as search paths
    for _, path in ipairs(include_paths) do
      if vim.fn.isdirectory(path) == 1 then
        cmd = cmd .. string.format(" '%s'", path)
      end
    end

    -- Filter for header files and use the search pattern
    cmd = cmd .. " --glob '*.h' --glob '*.hpp' --glob '*.hxx'"

    -- Only apply the grep pattern if query is not empty
    if query and query ~= "" then
      cmd = cmd .. string.format(" | grep -i '%s'", escaped_query)
    end

    return cmd
  end

  -- Return a function that Telescope can use for dynamic results
  return function(prompt)
    if prompt == nil then prompt = "" end

    local cmd = rg_command(prompt)
    local file_list = {}

    local handle = io.popen(cmd)
    if handle then
      for filepath in handle:lines() do
        -- Find which include path this header belongs to
        for _, include_path in ipairs(include_paths) do
          if filepath:sub(1, #include_path) == include_path then
            local relative_path = filepath:sub(#include_path + 2)
            table.insert(file_list, {
              path = filepath,
              relative_path = relative_path,
              include_path = include_path,
              is_system_header = true
            })
            break
          end
        end
      end
      handle:close()
    end

    return file_list
  end
end

-- Function to create a finder using ripgrep for project-wide headers
local function create_project_header_finder()
  -- Create the ripgrep command for project-wide search
  local rg_command = function(query)
    -- Escape the query
    local escaped_query = query:gsub("([^%w])", "\\%1")

    -- Build the command to search in current working directory
    local cmd = "rg --files ."

    -- Filter for header files
    cmd = cmd .. " --glob '*.h' --glob '*.hpp' --glob '*.hxx'"

    -- Only apply the grep pattern if query is not empty
    if query and query ~= "" then
      cmd = cmd .. string.format(" | grep -i '%s'", escaped_query)
    end

    return cmd
  end

  -- Return a function that Telescope can use for dynamic results
  return function(prompt)
    if prompt == nil then prompt = "" end

    local cmd = rg_command(prompt)
    local file_list = {}

    local handle = io.popen(cmd)
    if handle then
      for filepath in handle:lines() do
        -- Get the absolute path
        local abs_path = vim.fn.fnamemodify(filepath, ':p')
        table.insert(file_list, {
          path = abs_path,
          display_path = filepath
        })
      end
      handle:close()
    end

    return file_list
  end
end

-- Function to get compile command for current file using jq
local function get_compile_command()
  local current_file = vim.fn.expand('%:p')
  local compile_commands_path = vim.g.fuzzy_header_compile_commands or default_compile_commands_path
  if compile_commands_path == nil then
    vim.notify('Failed to find compile_commands.json path', vim.log.levels.ERROR)
    return nil
  end

  -- Check if compile_commands.json exists
  if vim.fn.filereadable(compile_commands_path) == 0 then
    print("Error: compile_commands.json not found at " .. compile_commands_path)
    return nil
  end

  -- Use jq to extract the compile command for current file
  local jq_cmd = string.format("jq -r '.[] | select(.file == \"%s\") | .command' %s", current_file, compile_commands_path)
  local handle = io.popen(jq_cmd)

  if not handle then
    print("Error: Failed to run jq command")
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  if result == "" or result == "null\n" then
    print("Error: Current file not found in compilation database")
    return nil
  end

  return result
end

-- Main function to show telescope picker for system headers
function M.find_system_header()
  -- Get compile command for current file
  local compile_command = get_compile_command()
  if not compile_command then
    return
  end

  -- Extract include paths from compile command
  local include_paths = extract_include_paths(compile_command)
  if #include_paths == 0 then
    print("No include paths found in compile command")
    return
  end

  -- Create a dynamic finder using ripgrep
  local header_finder = create_header_finder(include_paths)

  -- Create telescope picker with dynamic results
  pickers.new({}, {
    prompt_title = "System Header Files",
    finder = finders.new_dynamic {
      fn = header_finder,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.relative_path,
          ordinal = entry.relative_path,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Header Preview",
      define_preview = function(self, entry, status)
        local bufnr = self.state.bufnr
        local filepath = entry.value.path

        -- Read file content
        local fd = io.open(filepath, "r")
        if fd then
          local content = fd:read("*all")
          fd:close()

          -- Clear buffer and set content
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, '\n'))

          -- Set filetype for syntax highlighting
          vim.api.nvim_buf_set_option(bufnr, 'filetype', 'cpp')
        end
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection and selection.value then
          -- Determine the include path to use
          local header_path = selection.value.relative_path

          -- Insert #include directive at cursor position
          M.add_include(string.format("#include <%s>", header_path))
        end
      end)
      return true
    end,
  }):find()
end

-- Main function to find project headers (local headers)
function M.find_project_header()
  -- Create a dynamic finder for the whole project
  local project_finder = create_project_header_finder()

  -- Current file path for relative path computation
  local current_file = vim.fn.expand('%:p')

  -- Create telescope picker with dynamic results
  pickers.new({}, {
    prompt_title = "Project Header Files",
    finder = finders.new_dynamic {
      fn = project_finder,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display_path,
          ordinal = entry.display_path,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Header Preview",
      define_preview = function(self, entry, status)
        local bufnr = self.state.bufnr
        local filepath = entry.value.path

        -- Read file content
        local fd = io.open(filepath, "r")
        if fd then
          local content = fd:read("*all")
          fd:close()

          -- Clear buffer and set content
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, '\n'))

          -- Set filetype for syntax highlighting
          vim.api.nvim_buf_set_option(bufnr, 'filetype', 'cpp')
        end
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection and selection.value then
          -- Calculate relative path from current file to the selected header
          local rel_path = get_relative_path(current_file, selection.value.path)

          -- Insert #include directive at cursor position
          M.add_include(string.format('#include "%s"', rel_path))
        end
      end)
      return true
    end,
  }):find()
end

-- Alias the old function to the new name for backward compatibility
M.find_header = M.find_system_header
M.add_standard_header = function()
  vim.ui.input({
      prompt = "Enter the standard library header to add to add",
      default = ''
    },
    function(input)
      if input ~= nil then
        M.add_include(string.format('#include <%s>', input))
      end
    end
  )
end

-- Setup function for configuration
function M.setup(opts)
  opts = opts or {}
  if opts.compile_commands_path then
    vim.g.fuzzy_header_compile_commands = opts.compile_commands_path
  end
end

return M
