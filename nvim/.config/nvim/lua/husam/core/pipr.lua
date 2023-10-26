vim.keymap.set('n', '<Leader>pp', function()
  local Terminal      = require('toggleterm.terminal').Terminal
  local pipr_filename = '/tmp/pipr_output.txt'
  local pipr_output   = ''
  local pipr_term     = Terminal:new {
    cmd = 'pipr -o ' .. pipr_filename,
    direction = 'tab',
    dir = '.',
    close_on_exit = true,
    auto_scroll = true,
    on_stdout = function(t, job, data, name)
      local output = data[1]
      if string.len(output) > 0 then
        pipr_output = string.gsub(output, "\r", "")
      end
    end,
    on_exit = function(t, job, exit_code, name)
      local shell_output_path = '/tmp/pipr.sh'
      local shell_output = io.open(shell_output_path, "w")
      if shell_output then
        shell_output:write('#!/bin/bash\n')
        shell_output:write(pipr_output .. '\n')
        shell_output:close()
        local Job = require 'plenary.job'
        Job:new({
          command = '/bin/bash',
          args = { shell_output_path },
          cwd = '.',
          env = {},
          on_exit = function(j, return_val)
            if return_val ~= 0 then
              print('Command: \'' .. pipr_output .. '\'' .. ' failed!')
              return ""
            end
            local quickfix_list = {}
            for _, file_path in ipairs(j:result()) do
              table.insert(
                quickfix_list,
                {
                  filename = file_path,
                  lnum = 0,
                  col = 0,
                  text = file_path
                }
              )
            end
            vim.defer_fn(function()
              vim.fn.setqflist(quickfix_list)
              vim.cmd(':copen')
            end, 0)
          end,
        }):start()
      else
        print('Failed to write to file ' .. shell_output_path)
      end
    end
  }
  pipr_term:toggle()
end, {})
