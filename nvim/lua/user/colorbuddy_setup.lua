-- ColorBuddy configuration module for NeoSolarized theme
local M = {}

-- Setup the NeoSolarized theme
function M.setup()
  -- Check if colorbuddy is available
  local colorbuddy_ok, colorbuddy = pcall(require, "colorbuddy")
  if not colorbuddy_ok then
    vim.notify("colorbuddy.nvim not found. Install with :PackerSync", vim.log.levels.WARN)
    return
  end
  
  -- Try to load neosolarized
  local neosolarized_ok, neosolarized = pcall(require, "neosolarized")
  if neosolarized_ok then
    -- Setup neosolarized with options
    neosolarized.setup({
      comment_italics = true,
      background_set = false, -- Let Neovim control the background
      transparent = false,    -- Set to true for transparent background
    })
    vim.notify("NeoSolarized colorscheme applied", vim.log.levels.INFO)
    return
  else
    vim.notify("NeoSolarized not found. Install with :PackerSync", vim.log.levels.WARN)
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
end

return M 