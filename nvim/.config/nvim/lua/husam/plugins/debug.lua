return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require('dap')
      dap.adapters.node2 = {
        type = 'executable',
        command = 'node',
        args = { os.getenv('HOME') .. '/dev/microsoft/vscode-node-debug2/out/src/nodeDebug.js' },
      }
      dap.configurations.javascript = {
        {
          name = 'Launch',
          type = 'node2',
          request = 'launch',
          program = '${file}',
          cwd = vim.fn.getcwd(),
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
        command = '/home/hebaishi/Downloads/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
      }
      dap.adapters.python = function(cb, config)
        local bin_directory = 'Scripts'
        if vim.loop.os_uname().sysname == 'Linux' then
          bin_directory = 'bin'
        end
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
            command = vim.fn.expand("~") .. '/.virtualenvs/' .. bin_directory .. '/python',
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
          cwd = '${workspaceFolder}',
          stopAtEntry = false,
        }
        dap.configurations.cpp = { auto_detect_executable }
        dap.configurations.c = { auto_detect_executable }
        dap.configurations.python = {
          {
            type = "python",
            name = "Current File",
            request = "launch",
            program = "${file}",
            cwd = "${workspaceFolder}"
          }
        }
        require('dap.ext.vscode').load_launchjs(nil, { cppdbg = { 'c', 'cpp' } })
        require('dap').continue()
      end)
      vim.fn.sign_define('DapBreakpoint', { text = '', texthl = '', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped', { text = '󰁔', texthl = '', linehl = '', numhl = '' })
    end
  },
  {
    "rcarriga/nvim-dap-ui",
    lazy = false,
    dependencies = {
      "mfussenegger/nvim-dap"
    },
    config = function()
      require("dapui").setup({
        controls = {
          element = "repl",
          enabled = true,
          icons = {
            disconnect = "",
            pause = "",
            play = "",
            run_last = "",
            step_back = "",
            step_into = "",
            step_out = "",
            step_over = "",
            terminate = ""
          }
        },
        element_mappings = {},
        expand_lines = true,
        floating = {
          border = "single",
          mappings = {
            close = { "q", "<Esc>" }
          }
        },
        force_buffers = true,
        icons = {
          collapsed = "",
          current_frame = "",
          expanded = ""
        },
        layouts = { {
          elements = { {
            id = "scopes",
            size = 0.25
          }, {
            id = "breakpoints",
            size = 0.25
          }, {
            id = "stacks",
            size = 0.25
          }, {
            id = "watches",
            size = 0.25
          } },
          position = "left",
          size = 90
        }, {
          elements = { {
            id = "repl",
            size = 0.5
          }, {
            id = "console",
            size = 0.5
          } },
          position = "bottom",
          size = 10
        } },
        mappings = {
          edit = "e",
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          repl = "r",
          toggle = "t"
        },
        render = {
          indent = 1,
          max_value_lines = 100
        }
      })
    end
  },
}
