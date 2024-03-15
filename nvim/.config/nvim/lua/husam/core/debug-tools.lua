vim.keymap.set('n', '<leader>da', function()
  vim.ui.input({
      prompt = "Enter the command to debug",
      default = "",
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
        local current_buffer = vim.fn.expand('%')
        local expected_path = '.vscode/launch.json'
        if current_buffer == expected_path then
          local file_lines = ""
          for line in io.lines(current_buffer) do
            file_lines = file_lines .. line
          end
          local config = vim.json.decode(file_lines)
          table.insert(
            config.configurations,
            {
              type = "cppdbg",
              request = "launch",
              name = "${workspaceFolder}/" .. program,
              program = program,
              args = args,
              cwd = "${workspaceFolder}"
            }
          )
          vim.api.nvim_buf_set_lines(0, 0, -1, true, { vim.json.encode(config) })
          vim.lsp.buf.format()
        end
      end
    end)
end)
