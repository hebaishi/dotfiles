function prettifyJson(minified)
  local result = ""
  local indent = 0
  local inString = false
  local isEscaped = false

  local function addIndent()
    return string.rep("  ", indent)
  end

  for i = 1, #minified do
    local char = string.sub(minified, i, i)
    local prevChar = i > 1 and string.sub(minified, i - 1, i - 1) or ""

    -- Handle string literals
    if char == '"' and not isEscaped then
      inString = not inString
    end

    -- Track escape sequences
    isEscaped = char == "\\" and not isEscaped

    if not inString then
      -- Handle structural characters
      if char == "{" or char == "[" then
        result = result .. char .. "\n"
        indent = indent + 1
        result = result .. addIndent()
      elseif char == "}" or char == "]" then
        result = result .. "\n"
        indent = indent - 1
        result = result .. addIndent() .. char
      elseif char == "," then
        result = result .. char .. "\n" .. addIndent()
      elseif char == ":" then
        result = result .. char .. " "
      else
        -- Skip whitespace in non-string context
        if not string.match(char, "%s") then
          result = result .. char
        end
      end
    else
      -- In string context, preserve all characters
      result = result .. char
    end
  end

  return result
end
vim.keymap.set('n', '<leader>dt', function()
  require('dapui').toggle()
end, { desc = "Toggle DapUI" })

vim.keymap.set('n', '<leader>da', function()
  local Path = require('plenary.path')
  vim.ui.input({
      prompt = "Enter the command to debug",
      default = vim.fn.expand('%:t'),
      completion = "shellcmd"
    },
    function(input)
      if input ~= nil then
        local args = {}
        local first = true
        local program = ""
        for w in string.gmatch(input, "%S+") do
          if first then
            program = w
            first = false
          else
            table.insert(args, w)
          end
        end

        local type = 'codelldb'
        if program:match("%.py$") then
          type = 'python'
        elseif program:match("%.js$") then
          type = 'pwa-node'
        end
        local subdirectory = '.vscode'
        local launch_json_path = Path:new(vim.fn.getcwd() .. '/' .. subdirectory .. '/launch.json')
        local file_lines
        local config
        if launch_json_path:exists() then
          file_lines = launch_json_path:read()
          config = vim.json.decode(file_lines)
        else
          local subdirectory_path = vim.fn.getcwd() .. '/' .. subdirectory
          if vim.fn.isdirectory(subdirectory_path) ~= 1 then
            vim.fn.mkdir(subdirectory_path)
          end
          config = {
            version = "0.2.0",
            configurations = {}
          }
        end

        local new_config = {
          type = type,
          request = "launch",
          program = "${workspaceFolder}/" .. program,
          name = program,
          args = args,
          cwd = "${workspaceFolder}",
        }

        if new_config.type == 'cppdbg' then
          new_config.setupCommands = {
            {
              description = "Enable pretty-printing for gdb",
              text = "-enable-pretty-printing",
              ignoreFailures = true
            }
          }
        elseif new_config.type == 'codelldb' then
          new_config.preRunCommands = {
            "breakpoint name configure --disable cpp_exception"
          }
        elseif new_config.type == 'pwa-node' then
          new_config.runtimeArgs = {
            "--experimental-vm-modules",
            "./node_modules/jest/bin/jest.js",
            "--runInBand",
          }
          new_config.sourceMaps = true
          new_config.protocol = 'inspector'
          new_config.console = 'integratedTerminal'
        end

        table.insert(
          config.configurations,
          new_config
        )
        local json_str = vim.json.encode(config)
        json_str = json_str:gsub("\\/", "/")
        launch_json_path:write(prettifyJson(json_str), 'w')
      end
    end)
end, { desc = "Add debug entry" })
