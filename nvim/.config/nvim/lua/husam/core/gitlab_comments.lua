local gitlab = require('husam.utils.gitlab')
local M = {}
M.get_mr_comments = function()
  gitlab.create_glab_job(
    { "mr", "view", "-c", "--output", "json" },
    vim.uv.cwd(),
    vim.schedule_wrap(function(data)
      local quickfixlist = {}
      local notes = data.Notes or {}
      for _, value in ipairs(notes) do
        -- print(vim.inspect(value))
        if (value.type == 'DiffNote' and not value.resolved) then
          table.insert(quickfixlist, {
            filename = value.position.new_path,
            lnum = value.position.new_line,
            text = value.author.username .. ": " .. value.body,
            value = true,
            type = 'I',
          })
        end
      end
      if #notes > 0 then
        vim.cmd(':copen')
        vim.fn.setqflist(quickfixlist)
      end
    end)
  ):start()
end
return M
