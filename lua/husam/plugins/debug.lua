return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require('dap')
      dap.adapters.cppdbg = {
        id = 'cppdbg',
        type = 'executable',
        command = '/home/hebaishi/Downloads/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
      }
      dap.adapters.python = function(cb, config)
        if config.request == 'attach' then
          ---@diagnostic disable-next-line: undefined-field
          local port = (config.connect or config).port
          ---@diagnostic disable-next-line: undefined-field
          local host = (config.connect or config).host or '127.0.0.1'
          cb({
            type = 'server',
            port = assert(port, '`connect.port` is required for a python `attach` configuration'),
            host = host,
            options = {
              source_filetype = 'python',
            },
          })
        else
          cb({
            type = 'executable',
            command = vim.fn.expand("~") .. '/.virtualenvs/debugpy/bin/python',
            args = { '-m', 'debugpy.adapter' },
            options = {
              source_filetype = 'python',
            },
          })
        end
      end
      vim.keymap.set('n', '<F5>', function()
        local auto_detect_executable = {
          name = "Auto-detect Executable",
          type = "cppdbg",
          request = "launch",
          program = function()
            local lines_from = function(file)
              local lines = ""
              for line in io.lines(file) do
                lines = lines .. line
              end
              return lines
            end
            local decoded = vim.fn.json_decode(lines_from(vim.fn.getcwd() .. "/build/compile_commands.json"))
            local cwd = vim.fn.getcwd()
            local file_path =  cwd .. "/" .. vim.fn.expand('%')
            for k, v in pairs(decoded) do
              if (v.file == file_path)
              then
                local output_parameter = string.match(v.command, "-o [%a/%d%p]+")
                local suffix = ".dir"
                local output_directory = string.match(output_parameter, "[%a%d-_]+" .. suffix)
                local len = string.len(output_directory) - string.len(suffix)
                local target = string.sub(output_directory, 0, len)
                local target_path = v.directory .. '/bin/' .. target
                print('Found target: ' .. target_path)
                return target_path
              end
            end
            print('Failed to find target for file: ' .. file_path)
          end,
          cwd = '${workspaceFolder}',
          stopAtEntry = false,
        }
        dap.configurations.cpp = {auto_detect_executable}
        dap.configurations.c = {auto_detect_executable}
        require('dap.ext.vscode').load_launchjs(nil, { cppdbg = {'c', 'cpp'} })
        require('dap').continue()
      end)
      vim.fn.sign_define('DapBreakpoint', {text='', texthl='', linehl='', numhl=''})
      vim.fn.sign_define('DapStopped', {text='󰁔', texthl='', linehl='', numhl=''})
    end
  },
  "sakhnik/nvim-gdb",
  {
    "rcarriga/nvim-dap-ui",
    lazy = false,
    dependencies = {
      "mfussenegger/nvim-dap"
    },
    config = function()
      require("dapui").setup()
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end
  },
}
