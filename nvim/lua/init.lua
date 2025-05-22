-- Main initialization file for Neovim configuration
-- This serves as a simple entry point for Lua configuration

-- Check if we're running in Neovim
if vim.fn.has('nvim') == 0 then
  return
end

-- Permanently disable components that were causing issues
vim.g.skip_telescope = true  -- Disable Telescope
vim.g.skip_ts_tools = false  -- Set to true to disable TypeScript
vim.g.skip_treesitter_setup = false
vim.g.skip_plugin_installer = false  -- Enable the plugin installer

-- Add our lua directory to package.path
local config_path = vim.fn.stdpath('config')
local runtime_path = vim.fn.stdpath('data')
package.path = config_path .. "/lua/?.lua;" .. 
               config_path .. "/lua/?/init.lua;" ..
               config_path .. "/lua/user/?.lua;" ..
               runtime_path .. "/site/pack/packer/start/*/lua/?.lua;" ..
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

-- Helper function for TypeScript development
function setup_typescript()
  -- Check for typescript-tools.nvim
  local ts_tools = safe_require('typescript-tools')
  if not ts_tools then
    vim.notify("typescript-tools.nvim not found. TypeScript support will be limited.", vim.log.levels.WARN)
    return false
  end
  return true
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
        vim.fn.delete(treesitter_cache, 'rf')
      end
      
      -- Check for key plugins
      local plugin_checks = {
        {"typescript-tools", "TypeScript tools"},
        {"nvim-treesitter", "Treesitter"}
      }
      
      for _, plugin in ipairs(plugin_checks) do
        local name, desc = unpack(plugin)
        local ok, _ = pcall(require, name)
        if not ok then
          vim.notify(desc .. " plugin not found. Run :PlugInstall to install missing plugins.", vim.log.levels.WARN)
        end
      end
    end, 1000)
  end,
  pattern = "*"
})

-- We're keeping most configuration in init.vim with only some
-- minimal Lua configuration as requested by the user.
-- Individual Lua modules will be loaded directly from init.vim.

-- This file is loaded from init.vim with:
-- lua require('init') 