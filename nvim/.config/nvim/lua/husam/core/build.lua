local job = nil
local run_id = 0

local function async_run(cmd)
  if job then
    job:kill(9)
    job = nil
  end
  run_id = run_id + 1
  local current_id = run_id
  vim.fn.setqflist({}, "r", { title = cmd, items = {} })
  local start = vim.uv.hrtime()
  job = vim.system({ "sh", "-c", cmd }, {
    stdout = function(_, data)
      if data and run_id == current_id then
        vim.schedule(function()
          if run_id == current_id then
            vim.fn.setqflist({}, "a", { lines = vim.split(data, "\n", { plain = true }) })
          end
        end)
      end
    end,
    stderr = function(_, data)
      if data and run_id == current_id then
        vim.schedule(function()
          if run_id == current_id then
            vim.fn.setqflist({}, "a", { lines = vim.split(data, "\n", { plain = true }) })
          end
        end)
      end
    end,
  }, function(result)
    if run_id == current_id then
      local elapsed = (vim.uv.hrtime() - start) / 1e9
      vim.schedule(function()
        if run_id == current_id then
          vim.fn.setqflist({}, "a", {
            lines = { string.format("[exit %d | %.2fs]", result.code, elapsed) },
          })
        end
      end)
    end
  end)
end
vim.api.nvim_create_user_command("AsyncRun", function(opts)
  async_run(opts.args)
end, { nargs = "+" })
