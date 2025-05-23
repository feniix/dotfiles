-- NeoSolarized colorscheme configuration
-- Migrated from user/colorbuddy_setup.lua

local M = {}

function M.setup()
  -- Setup NeoSolarized through colorbuddy
  local safe_require = _G.safe_require or require
  local colorbuddy = safe_require('colorbuddy')
  
  if not colorbuddy then
    vim.notify("colorbuddy not found, cannot setup NeoSolarized", vim.log.levels.WARN)
    return
  end

  -- Initialize colorbuddy
  colorbuddy.colorscheme('neosolarized')
  
  -- Create a command to toggle between light and dark modes
  vim.api.nvim_create_user_command('ToggleTheme', function()
    M.toggle_theme()
  end, { desc = 'Toggle between light and dark Solarized themes' })
end

function M.toggle_theme()
  if vim.opt.background:get() == "dark" then
    vim.opt.background = "light"
  else
    vim.opt.background = "dark"
  end
  
  -- Reload the colorscheme
  local colorbuddy = require('colorbuddy')
  if colorbuddy then
    colorbuddy.colorscheme('neosolarized')
  end
end

return M 