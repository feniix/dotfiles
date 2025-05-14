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

-- Function to load the main user configuration
local function load_user_config()
  -- Get the user config module
  local user_config_ok, user_config = pcall(require, "user")
  if not user_config_ok then
    vim.notify("Could not load main user configuration. Using fallback configuration.", vim.log.levels.ERROR)
    
    -- Load individual modules as fallback
    -- Setup editor options
    local options = safe_require('user.options')
    if options then options.setup() end
    
    -- Setup plugin configurations
    local plugins = safe_require('user.plugins')
    if plugins then plugins.setup() end
    
    -- Setup UI components
    local ui = safe_require('user.ui')
    if ui then ui.setup() end
    
    -- Setup keymaps
    local keymaps = safe_require('user.keymaps')
    if keymaps then keymaps.setup() end
    
    -- Setup completion
    local completion = safe_require('user.completion')
    if completion then completion.setup() end
    
    return
  end
  
  -- Use unified setup method
  user_config.setup()
  
  -- Make individual setup functions available globally
  _G.setup_options = user_config.setup_options
  _G.setup_plugins = user_config.setup_plugins
  _G.setup_ui = user_config.setup_ui
  _G.setup_keymaps = user_config.setup_keymaps
  _G.setup_completion = user_config.setup_completion
  _G.setup_language = user_config.setup_language
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

      -- Load all configuration modules
      load_user_config()
    end, 1000)
  end,
  pattern = "*"
})

-- Make safe_require globally available
_G.safe_require = safe_require

-- This file is loaded from init.vim with:
-- lua require('init') 
-- Individual modules can be loaded with:
-- lua _G.setup_options()
-- lua _G.setup_plugins()
-- lua _G.setup_ui()
-- lua _G.setup_keymaps()
-- lua _G.setup_completion() 