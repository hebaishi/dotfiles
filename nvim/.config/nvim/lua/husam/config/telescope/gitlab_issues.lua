-- telescope-glab.nvim
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
-- local async = require('plenary.async')
local Job = require('plenary.job')
local glab_cmd = vim.fn.expand("~/go/bin/glab")

local M = {}

-- Helper function to create an async job
local function create_glab_job(cmd_args, cwd, callback)
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

-- Issue previewer
local issue_previewer = previewers.new_buffer_previewer({
  title = "Issue Preview",
  get_buffer_by_name = function(_, entry)
    return entry.value.id
  end,
  define_preview = function(self, entry, status)
    -- Set initial loading message
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Loading issue details..." })

    -- Create the job
    local job = create_glab_job(
      { 'issue', 'view', entry.value.iid, '--output', 'json' },
      vim.uv.cwd(),
      vim.schedule_wrap(function(issue_data)
        -- Check if preview is still valid
        if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
          return
        end

        -- Format the preview
        local preview_lines = {
          string.format("# %s", issue_data.title),
          string.format("ID: #%s", issue_data.iid),
          string.format("State: %s", issue_data.state),
          string.format("Author: @%s", issue_data.author.username),
          string.format("Created: %s", issue_data.created_at),
          string.format("Updated: %s", issue_data.updated_at),
          string.format("Web URL: %s", issue_data.web_url),
          "",
        }

        if issue_data.labels and #issue_data.labels > 0 then
          table.insert(preview_lines, "Labels: " .. table.concat(issue_data.labels, ", "))
        end

        -- if issue_data.milestone then
        --   table.insert(preview_lines, "Milestone: " .. issue_data.milestone.title)
        -- end

        if issue_data.assignees and #issue_data.assignees > 0 then
          local assignee_names = vim.tbl_map(function(a) return a.username end, issue_data.assignees)
          table.insert(preview_lines, "Assignees: " .. table.concat(assignee_names, ", "))
        end

        if issue_data.description then
          table.insert(preview_lines, "")
          table.insert(preview_lines, "Description:")
          table.insert(preview_lines, "------------")
          local lines = vim.split(issue_data.description, '\n')
          for i = 1, #lines do
            table.insert(preview_lines, lines[i])
          end
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'markdown')
      end)
    )

    -- Start the job
    job:start()

    -- Return a cleanup function
    return function()
      job:shutdown()
    end
  end,
})

-- Main function to search GitLab issues
local function search_issues(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  -- Create initial picker with loading message
  local picker = pickers.new(opts, {
    debounce = 500,
    prompt_title = "GitLab Issues",
    finder = finders.new_table({
      results = {},
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("#%s %s (%s) @%s",
            entry.iid,
            entry.title,
            entry.state,
            entry.author.username
          ),
          ordinal = string.format("#%s %s %s %s",
            entry.iid,
            entry.title,
            entry.state,
            entry.author.username
          ),
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = issue_previewer,
  })

  -- Start the picker
  picker:find()

  -- Create args for glab command
  local cmd_args = { 'issue', 'list', '--output', 'json' }
  if opts.query then
    table.insert(cmd_args, '--search')
    table.insert(cmd_args, opts.query)
  end

  -- Fetch issues asynchronously
  create_glab_job(
    cmd_args,
    opts.cwd,
    vim.schedule_wrap(function(issues)
      -- Update the finder with the results
      picker:refresh(finders.new_table({
        results = issues,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format("#%s %s (%s) @%s",
              entry.iid,
              entry.title,
              entry.state,
              entry.author.username
            ),
            ordinal = string.format("#%s %s %s %s",
              entry.iid,
              entry.title,
              entry.state,
              entry.author.username
            ),
          }
        end,
      }))
    end)
  ):start()
end

-- Setup function
function M.setup(opts)
  -- Check if glab is installed
  if vim.fn.executable(glab_cmd) ~= 1 then
    error("glab CLI tool is not installed. Please install it first.")
  end
  search_issues(opts)
end

return M
