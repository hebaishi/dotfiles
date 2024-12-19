local Job = require('plenary.job')
local glab_cmd = vim.fn.expand("~/go/bin/glab")
local M = {}
-- Helper function to create an async job
M.create_glab_job = function(cmd_args, cwd, callback)
  return Job:new({
    command = glab_cmd,
    args = cmd_args,
    cwd = cwd,
    on_exit = function(j, return_val)
      if return_val == 0 then
        local output = j:result()
        local json_str = table.concat(output, "")
        local ok, parsed = pcall(vim.json.decode, json_str)
        if ok then
          callback(parsed)
        else
          vim.schedule(function()
            vim.notify("Failed to parse JSON output from glab", vim.log.levels.ERROR)
          end)
          callback({})
        end
      else
        vim.schedule(function()
          vim.notify("glab command failed: " .. table.concat(j:stderr_result(), "\n"), vim.log.levels.ERROR)
        end)
        callback({})
      end
    end,
  })
end

return M
