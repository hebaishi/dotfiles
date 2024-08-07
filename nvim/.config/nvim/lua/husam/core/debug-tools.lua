vim.keymap.set('n', '<leader>da', function()
  vim.cmd('e .vscode/launch.json')
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
            program = "${workspaceFolder}/" .. program,
            name = program,
            args = args,
            cwd = "${workspaceFolder}",
            setupCommands = {
              {
                description = "Enable pretty-printing for gdb",
                text = "-enable-pretty-printing",
                ignoreFailures = true
              }
            },
          }
        )
        local json_str = vim.json.encode(config)
        json_str = json_str:gsub("\\/", "/")
        vim.api.nvim_buf_set_lines(0, 0, -1, true, { json_str })
        vim.cmd('%!jq')
      end
    end)
end, { desc = "Add debug entry" })
