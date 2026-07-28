local job = nil
local run_id = 0

local function split_lines(data)
  local lines = vim.split(data, "\n", { plain = true })
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  return lines
end

local function make_output_handler(current_id)
  return function(_, data)
    if data and run_id == current_id then
      vim.schedule(function()
        if run_id == current_id then
          vim.fn.setqflist({}, "a", { lines = split_lines(data) })
          vim.cmd("cbottom")
        end
      end)
    end
  end
end

local function async_run(cmd)
  if job then
    job:kill(9)
    job = nil
  end
  run_id = run_id + 1
  local current_id = run_id
  vim.fn.setqflist({}, "r", { title = cmd, items = {} })
  vim.cmd("cbottom")
  local start = vim.uv.hrtime()
  local handle_output = make_output_handler(current_id)
  job = vim.system({ "sh", "-c", cmd }, {
    stdout = handle_output,
    stderr = handle_output,
  }, function(result)
    if run_id == current_id then
      local elapsed = (vim.uv.hrtime() - start) / 1e9
      vim.schedule(function()
        if run_id == current_id then
          vim.fn.setqflist({}, "a", {
            lines = { string.format("[exit %d | %.2fs]", result.code, elapsed) },
          })
          vim.cmd("cbottom")
        end
      end)
    end
  end)
end
vim.api.nvim_create_user_command("AsyncRun", function(opts)
  async_run(opts.args)
end, { nargs = "+" })
