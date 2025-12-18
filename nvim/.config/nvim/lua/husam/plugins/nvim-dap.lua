local function find_package_json_path()
  -- Get the current buffer's full path
  local current_file = vim.fn.expand('%:p')
  -- Get the directory of the current file
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  -- Keep going up until we find package.json or hit root
  local current_path = current_dir
  while current_path ~= '/' do
    local package_path = current_path .. '/package.json'
    if vim.fn.filereadable(package_path) == 1 then
      return current_path
    end
    -- Go up one directory
    current_path = vim.fn.fnamemodify(current_path, ':h')
  end

  -- Check root directory as final attempt
  if vim.fn.filereadable('/package.json') == 1 then
    return '.'
  end

  return vim.fn.getcwd()
end

return {
  "mfussenegger/nvim-dap",
  config = function()
    local dap = require('dap')
    local home = vim.fn.expand('~')
    local Path = require('plenary.path')
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = {
          home .. "/dev/js-debug/src/dapDebugServer.js",
          "${port}",
        },
      }
    }
    dap.configurations.javascript = {
      {
        name = 'Launch',
        type = 'pwa-node',
        request = 'launch',
        program = '${file}',
        cwd = find_package_json_path,
        sourceMaps = true,
        protocol = 'inspector',
        console = 'integratedTerminal',
      },
      {
        name = 'Launch Jest',
        type = 'pwa-node',
        request = 'launch',
        runtimeArgs = {
          "--experimental-vm-modules",
          "./node_modules/jest/bin/jest.js",
          "--runInBand",
        },
        cwd = find_package_json_path,
        sourceMaps = true,
        protocol = 'inspector',
        console = 'integratedTerminal',
      },
      {
        -- For this to work you need to make sure the node process is started with the `--inspect` flag.
        name = 'Attach to process',
        type = 'node2',
        request = 'attach',
        processId = require 'dap.utils'.pick_process,
      },
    }
    dap.adapters.cppdbg = {
      id = 'cppdbg',
      type = 'executable',
      command = home .. '/dev/extension/debugAdapters/bin/OpenDebugAD7',
    }
    dap.adapters.codelldb = {
      id = 'codelldb',
      type = 'executable',
      command = home .. '/dev/codelldb/extension/adapter/codelldb',
    }
    vim.keymap.set('n', '<F5>', function()
      local auto_detect_executable = {
        name = "Auto-detect Executable",
        type = "codelldb",
        request = "launch",
        preRunCommands = {
          "breakpoint name configure --disable cpp_exception"
        },
        program = function()
          local file_path = vim.fn.expand('%:p')
          local get_current_executable = function()
            local Job = require 'plenary.job'

            local function trim(s)
              return (s:gsub("^%s*(.-)%s*$", "%1"))
            end
            local outputs = { file_path }
            local process_one = function()
              Job:new({
                command = 'ninja',
                args = { '-t', 'query', outputs[#outputs] },
                cwd = vim.fn.getcwd() .. '/build',
                env = {},
                on_exit = function(j, return_val)
                  if return_val == 0 then
                    local current_mode = ''
                    for _, value in ipairs(j:result()) do
                      local trimmed_string = trim(value)
                      if trimmed_string == 'inputs:' then
                        current_mode = 'input'
                      elseif trimmed_string == 'outputs:' then
                        current_mode = 'output'
                      elseif current_mode == 'output' then
                        table.insert(outputs, trim(value))
                      else
                        current_mode = ''
                      end
                    end
                  end
                end
              }):sync() -- or start()
            end
            local function endsWith(str, ending)
              return ending == "" or string.sub(str, -string.len(ending)) == ending
            end
            local max_iterations = 5
            for _ = 1, max_iterations do
              local current_output = outputs[#outputs]
              if not endsWith(current_output, '.o') and not endsWith(current_output, '.cpp') then
                return vim.fn.getcwd() .. '/build/' .. current_output
              else
                process_one()
              end
            end
            print('Failed to find target for file: ' .. file_path)
          end
          return get_current_executable()
        end,
        cwd = '${workspaceFolder}/build/bin',
        setupCommands = {
          {
            description = "Enable pretty-printing for gdb",
            text = "-enable-pretty-printing",
            ignoreFailures = true
          }
        },
        stopAtEntry = false,
      }
      dap.configurations.cpp = { auto_detect_executable }
      dap.configurations.c = { auto_detect_executable }
      require('dap').continue()
    end)
    local dapui = require("dapui")
    vim.fn.sign_define('DapBreakpoint', { text = '', texthl = '', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '󰁔', texthl = '', linehl = '', numhl = '' })
    vim.keymap.set('n', '<F3>', function()
      require('dap').terminate()
      dapui.close()
    end, {})
    vim.keymap.set('n', '<F9>', function()
      require('dap').toggle_breakpoint()
    end, {})
    vim.keymap.set('n', '<F8>', function()
      require('dap').step_into()
    end, {})
    vim.keymap.set('n', '<F10>', function()
      require('dap').step_over()
    end, {})
  end
}
