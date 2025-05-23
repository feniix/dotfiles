-- Main initialization file for Neovim configuration
-- This serves as a simple entry point for Lua configuration

-- Check if we're running in Neovim
if vim.fn.has('nvim') == 0 then
  return
end

-- Permanently disable components that were causing issues
vim.g.skip_ts_tools = true   -- Disable TypeScript
vim.g.skip_treesitter_setup = false
vim.g.skip_plugin_installer = false  -- Enable the plugin installer

-- Add our lua directory to package.path
local config_path = vim.fn.stdpath('config')
local runtime_path = vim.fn.stdpath('data')
package.path = config_path .. "/lua/?.lua;" .. 
               config_path .. "/lua/?/init.lua;" ..
               config_path .. "/lua/user/?.lua;" ..
               package.path

-- Helper function to safely require modules with better error reporting
function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    -- Get more detailed error message
    local err_msg = "Could not load module: " .. module
    
    -- Try to check if the module file exists
    local module_path = module:gsub("%.", "/")
    local file_exists = false
    
    -- Check in common paths
    for _, path in ipairs({
      config_path .. "/lua/" .. module_path .. ".lua",
      config_path .. "/lua/" .. module_path .. "/init.lua"
    }) do
      if vim.fn.filereadable(path) == 1 then
        file_exists = true
        err_msg = err_msg .. " (File exists but couldn't be loaded, check for syntax errors)"
        break
      end
    end
    
    if not file_exists then
      err_msg = err_msg .. " (File not found)"
    end
    
    vim.notify(err_msg, vim.log.levels.WARN)
    return nil
  end
  return result
end

-- Load and initialize cross-platform detection
local platform = safe_require('user.platform')
if platform then
  -- Apply platform-specific configurations early
  platform.apply_config()
end

-- Set up health check module
pcall(function() 
  local health = require("user.health")
  health.setup()
end)

-- Clear cache directory on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      -- Clean treesitter cache directory to prevent issues
      local treesitter_cache = vim.fn.stdpath('cache') .. '/treesitter-vim'
      if vim.fn.isdirectory(treesitter_cache) == 1 then
        local ok, err = pcall(vim.fn.delete, treesitter_cache, 'rf')
        if not ok then
          vim.notify("Failed to clean treesitter cache: " .. tostring(err), vim.log.levels.WARN)
        end
      end
    end, 1000)
  end,
  pattern = "*"
})

-- Make safe_require globally available
_G.safe_require = safe_require

-- Make platform detection globally available for backward compatibility
if platform then
  _G.is_iterm2 = platform.is_iterm2
  _G.is_mac = platform.is_mac
  _G.is_windows = platform.is_windows
  _G.is_linux = platform.is_linux
  -- Also make the platform module globally available
  _G.platform = platform
else
  -- Fallback functions if platform module fails to load
  _G.is_iterm2 = function()
    return vim.env.TERM_PROGRAM == "iTerm.app" or 
           (vim.env.TERM and string.match(vim.env.TERM, "^iterm")) or 
           vim.env.LC_TERMINAL == "iTerm2"
  end
  _G.is_mac = function() return vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 end
  _G.is_windows = function() return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 end
  _G.is_linux = function() return vim.fn.has("unix") == 1 and not is_mac() end
end

-- We're keeping most configuration in individual Lua modules for better organization
-- The entry point is now init.lua in the nvim directory root

-- This file is loaded from init.lua with:
-- require('init') 