return {
  "ThePrimeagen/harpoon",
  config = function()
    for i = 1, 5 do
      vim.keymap.set('n', '<A-' .. tostring(i) .. '>', function()
        if vim.loop.os_uname().sysname == 'Linux' then
          require("harpoon.tmux").sendCommand(tostring(i), i)
          require("harpoon.tmux").sendCommand(tostring(i), '\n')
        else
          local cmd = require("harpoon").get_term_config().cmds[i]
          local buffers = vim.api.nvim_list_bufs()

          -- Iterate through the buffers and filter out the terminal buffers
          local terminal_buffers = {}
          for _, bufnr in ipairs(buffers) do
            local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
            if buftype == 'terminal' then
              table.insert(terminal_buffers, bufnr)
            end
          end
          local terminal_job_id = vim.api.nvim_buf_get_var(terminal_buffers[i], "terminal_job_id")
          vim.api.nvim_chan_send(terminal_job_id, cmd .. "\r\n")
        end
      end, {desc = "Send command " .. tostring(i) .. " to pane " .. tostring(i)})
    end
  end
}
