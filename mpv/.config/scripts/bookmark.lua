-- bookmark.lua - Save video timestamps to text file
-- Place this file in: ~/.config/mpv/scripts/ (Linux/Mac) or %APPDATA%/mpv/scripts/ (Windows)

local utils = require 'mp.utils'
local msg = require 'mp.msg'

-- Configuration
local bookmark_file = "bookmarks.txt" -- Change this to your preferred filename/path

function save_bookmark()
  local time_pos = mp.get_property_number("time-pos")
  local filename = mp.get_property("filename")

  if not time_pos then
    mp.osd_message("No video loaded")
    return
  end

  -- Format timestamp as HH:MM:SS.mmm
  local hours = math.floor(time_pos / 3600)
  local minutes = math.floor((time_pos % 3600) / 60)
  local seconds = time_pos % 60
  local timestamp = string.format("%02d:%02d:%06.3f", hours, minutes, seconds)

  -- Also get seconds for ffmpeg
  local timestamp_seconds = string.format("%.3f", time_pos)

  -- Create bookmark entry
  local bookmark_entry = string.format("%s | %s | %s seconds | %s\n",
    os.date("%Y-%m-%d %H:%M:%S"),
    filename,
    timestamp,
    timestamp_seconds
  )

  -- Append to file
  local file = io.open(bookmark_file, "a")
  if file then
    file:write(bookmark_entry)
    file:close()
    mp.osd_message("Bookmark saved: " .. timestamp)
    msg.info("Bookmark saved: " .. bookmark_entry:gsub("\n", ""))
  else
    mp.osd_message("Error: Could not write to bookmark file")
    msg.error("Could not write to bookmark file: " .. bookmark_file)
  end
end

-- Bind the 'b' key to save bookmark
mp.add_key_binding("b", "save-bookmark", save_bookmark)
