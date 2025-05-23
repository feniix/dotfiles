-- ColorBuddy configuration for NeoSolarized theme
-- Migrated from user/colorbuddy_setup.lua

local M = {}

-- Setup the NeoSolarized theme
function M.setup()
  local safe_require = _G.safe_require or require
  local colorbuddy = safe_require("colorbuddy")
  
  if not colorbuddy then
    vim.notify("colorbuddy.nvim not found. Install with :Lazy sync", vim.log.levels.WARN)
    return
  end
  
  -- Load colorbuddy
  local Color, colors, Group, groups, styles = colorbuddy.setup()
  
  -- Load NeoSolarized theme - try different module names
  local neosolarized = safe_require("NeoSolarized") or safe_require("neosolarized")
  if neosolarized then
    -- Setup neosolarized with options
    neosolarized.setup({
      comment_italics = true,
      background_set = false, -- Let Neovim control the background
      transparent = false,    -- Set to true for transparent background
    })
    return
  else
    vim.notify("NeoSolarized not found. Install with :Lazy sync", vim.log.levels.WARN)
  end
end

-- Toggle between light and dark Solarized
function M.toggle_theme()
  -- Get current background
  local current_bg = vim.opt.background:get()
  
  -- Toggle between light and dark
  if current_bg == "dark" then
    vim.opt.background = "light"
    vim.notify("Light Solarized theme applied", vim.log.levels.INFO)
  else
    vim.opt.background = "dark"
    vim.notify("Dark Solarized theme applied", vim.log.levels.INFO)
  end
  
  -- Trigger colorscheme reapplication
  pcall(vim.cmd, 'colorscheme NeoSolarized')
end

-- Create user command for theme toggling
function M.setup_commands()
  vim.api.nvim_create_user_command('ToggleTheme', M.toggle_theme, {
    desc = 'Toggle between light and dark Solarized theme'
  })
end

return M 