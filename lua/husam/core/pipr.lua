vim.keymap.set('n', '<Leader>pp', function()
  local Terminal      = require('toggleterm.terminal').Terminal
  local async         = require("plenary.async")
  local pipr_filename = '/tmp/pipr_output.txt'
  local fn            = vim.fn
  local pipr_term     = Terminal:new {
    cmd = 'pipr -o ' .. pipr_filename,
    direction = 'tab',
    dir = '.',
    close_on_exit = true,
    auto_scroll = true,
    on_exit = function(t, job, exit_code, name)
      local pipr_output_file = io.open(pipr_filename, "r")
      if pipr_output_file then
        -- File was opened successfully
        -- Read the contents of the file here
        local command = pipr_output_file:read("*a") -- Read the entire file
        local shell_output_path = '/tmp/pipr.sh'
        local shell_output = io.open(shell_output_path, "w")
        if shell_output then
          shell_output:write('#!/bin/bash\n')
          shell_output:write(command .. '\n')
          shell_output:close()
          local Job = require 'plenary.job'
          Job:new({
            command = '/bin/bash',
            args = { shell_output_path },
            cwd = '.',
            env = {},
            on_exit = function(j, return_val)
              if return_val ~= 0 then
                print('Command: \'' .. command .. '\'' .. ' failed!')
              end
              local quickfix_list = {}
              for _, file_path in ipairs(j:result()) do
                table.insert(
                  quickfix_list,
                  {
                    filename = file_path,
                    lnum = 0,
                    col = 0,
                    text = "Pipr output",
                  }
                )
              end
              -- Define the Vimscript code as a string
              vim.defer_fn(function()
                vim.fn.setqflist(quickfix_list)
                vim.cmd(':copen')
              end, 0)
            end,
          }):start()
        else
          print('Failed to write to file ' .. shell_output_path)
        end
        pipr_output_file:close()
      else
        print("File not found or couldn't be opened.")
      end
    end
  }
  pipr_term:toggle()
end, {})
