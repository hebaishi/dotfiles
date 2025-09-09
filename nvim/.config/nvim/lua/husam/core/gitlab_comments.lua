local gitlab = require('husam.utils.gitlab')
local M = {}
M.job_running = false
M.items_per_page = 100
M.collected_items = {}
M.current_page = 0
M.create_job = function(page, callback)
  gitlab.create_glab_job(
    { "mr", "view", "-c", "--output", "json", "--page", tostring(page), "--per-page", tostring(M.items_per_page) },
    vim.uv.cwd(),
    vim.schedule_wrap(function(data)
      local notes = data.Notes or {}
      for _, value in ipairs(notes) do
        if (value.type == "DiffNote" and not value.resolved) then
          table.insert(M.collected_items, {
            filename = value.position.new_path,
            lnum = value.position.new_line,
            text = value.author.username .. ": " .. value.body,
            value = true,
            type = 'I',
          })
        end
      end
      print("Got " ..
        tostring(#notes) ..
        " items and collected " .. #M.collected_items .. " diffnotes in page " .. tostring(M.current_page))
      if #notes < M.items_per_page then
        callback(M.collected_items)
      else
        M.current_page = M.current_page + 1
        M.create_job(M.current_page, callback)
      end
    end)
  ):start()
end
M.get_mr_comments = function()
  if M.job_running == false then
    M.job_running = true
    M.current_page = 0
    M.collected_items = {}
    M.create_job(0, function(quickfixlist)
      if #quickfixlist > 0 then
        vim.cmd(':copen')
        vim.fn.setqflist(quickfixlist)
      else
        vim.notify("Found 0 unresolved diff notes!", "info")
      end
      M.job_running = false
    end)
  else
    print('Gitlab comments job already running"')
  end
end
return M
