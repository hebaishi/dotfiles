local function get_git_status()
  local handle = io.popen('git status -u --porcelain 2>/dev/null')
  if not handle then
    return {}, {}
  end

  local result = handle:read('*a')
  handle:close()

  if not result or result == '' then
    return {}, {}
  end

  local added_files = {}
  local deleted_files = {}

  for line in result:gmatch('[^\r\n]+') do
    local status = line:sub(1, 2)
    local file = line:sub(4)

    if status:match('^%?%?') then
      table.insert(added_files, file)
    elseif status:match('^.D') or status:match('^D.') then
      table.insert(deleted_files, file)
    end
  end

  return added_files, deleted_files
end

local function get_current_cmake_dir()
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  return current_dir
end

local function is_in_subdirectory(file_path, base_dir)
  local abs_file = vim.fn.fnamemodify(file_path, ':p')
  local abs_base = vim.fn.fnamemodify(base_dir, ':p')

  -- Ensure both paths end with /
  if not abs_base:match('/$') then
    abs_base = abs_base .. '/'
  end

  return abs_file:sub(1, #abs_base) == abs_base
end

local function get_relative_path(file_path, base_dir)
  local abs_file = vim.fn.fnamemodify(file_path, ':p')
  local abs_base = vim.fn.fnamemodify(base_dir, ':p')

  if not abs_base:match('/$') then
    abs_base = abs_base .. '/'
  end

  if abs_file:sub(1, #abs_base) == abs_base then
    return abs_file:sub(#abs_base + 1)
  end

  return file_path
end

local function remove_deleted_files_from_buffer(deleted_files, base_dir)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local lines_to_remove = {}

  for i, line in ipairs(lines) do
    local trimmed = line:match('^%s*(.-)%s*$')
    if trimmed and trimmed ~= '' then
      -- Check if this line contains a file path
      for _, deleted_file in ipairs(deleted_files) do
        local rel_path = get_relative_path(deleted_file, base_dir)
        if trimmed:find(rel_path, 1, true) then
          table.insert(lines_to_remove, i - 1) -- Convert to 0-based indexing
          break
        end
      end
    end
  end

  -- Remove lines in reverse order to maintain correct indices
  for i = #lines_to_remove, 1, -1 do
    vim.api.nvim_buf_set_lines(0, lines_to_remove[i], lines_to_remove[i] + 1, false, {})
  end

  if #lines_to_remove > 0 then
    print(string.format('Removed %d deleted file(s) from CMakeLists.txt', #lines_to_remove))
  end
end

local function add_untracked_files_at_cursor(added_files, base_dir)
  local relevant_files = {}

  for _, file in ipairs(added_files) do
    if is_in_subdirectory(file, base_dir) then
      local rel_path = get_relative_path(file, base_dir)
      table.insert(relevant_files, rel_path)
    end
  end

  if #relevant_files == 0 then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-based indexing

  -- Insert each file path at the cursor position
  for i, file_path in ipairs(relevant_files) do
    vim.api.nvim_buf_set_lines(0, row + i - 1, row + i - 1, false, { file_path })
  end

  print(string.format('Added %d untracked file(s) to CMakeLists.txt', #relevant_files))
end

local function sync_cmake_files()
  local added_files, deleted_files = get_git_status()
  local current_dir = get_current_cmake_dir()

  -- Remove deleted files first
  remove_deleted_files_from_buffer(deleted_files, current_dir)

  -- Add untracked files at cursor
  add_untracked_files_at_cursor(added_files, current_dir)
end

-- Create the autocommand
vim.api.nvim_create_user_command('CMakeSync', sync_cmake_files, {
  desc = 'Sync CMakeLists.txt with git status (add untracked, remove deleted files)'
})
