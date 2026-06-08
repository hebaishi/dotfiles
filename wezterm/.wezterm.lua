-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.font_size = 12.0
config.hide_tab_bar_if_only_one_tab = true

-- For streaming
-- config.font = wezterm.font('SauceCodePro NF Medium')
-- For day-to-day
config.font = wezterm.font('Input Nerd Font')
if wezterm.target_triple:find('windows') then
  config.default_prog = { 'powershell.exe' }
end

-- Load SSH domains dynamically from ~/.ssh/config
local function load_ssh_domains()
  local domains = {}
  local ssh_config_path = wezterm.home_dir .. '/.ssh/config'
  local f = io.open(ssh_config_path, 'r')
  if not f then
    return domains
  end
  for line in f:lines() do
    local host = line:match('^%s*Host%s+(%S+)%s*$')
    if host and not host:find('[*?]') then
      table.insert(domains, {
        name = host,
        remote_address = host,
        multiplexing = 'None',
      })
    end
  end
  f:close()
  return domains
end

config.ssh_domains = load_ssh_domains()
config.default_domain = 'local'

-- and finally, return the configuration to wezterm
return config

